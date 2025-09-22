#!/bin/bash

echo "=== DoneEZ Deployment Debug Script ==="
echo "Timestamp: $(date)"
echo ""

echo "1. Checking nginx status and configuration..."
sudo systemctl status nginx --no-pager
echo ""

echo "2. Testing nginx configuration..."
sudo nginx -t
echo ""

echo "3. Checking nginx error logs (last 20 lines)..."
sudo tail -20 /var/log/nginx/error.log
echo ""

echo "4. Checking what's listening on ports 80, 3000, 8000..."
sudo netstat -tlnp | grep -E ':80|:3000|:8000'
echo ""

echo "5. Checking PM2 process details..."
pm2 list
echo ""

echo "6. Checking PM2 logs for errors..."
pm2 logs --lines 10
echo ""

echo "7. Checking if services respond locally..."
echo "Testing frontend (port 3000):"
curl -I http://localhost:3000 2>/dev/null || echo "Frontend not responding"
echo ""
echo "Testing backend (port 8000):"
curl -I http://localhost:8000 2>/dev/null || echo "Backend not responding"
echo ""

echo "8. Checking Python environment and Django..."
echo "Python version:"
python3 --version
echo ""
echo "Python path:"
python3 -c "import sys; print('\n'.join(sys.path))"
echo ""
echo "Checking if Django is installed:"
python3 -c "import django; print(f'Django version: {django.get_version()}')" 2>/dev/null || echo "Django not found!"
echo ""
echo "Checking Django backend status..."
cd /root/autofix-pro-digital-ocean-code/DoneEZ/DoneEZ
if [ -f "manage.py" ]; then
    echo "Django project found. Checking if it can start..."
    python3 manage.py check --deploy 2>/dev/null || echo "Django check failed"
    echo ""
    echo "Testing Django import directly:"
    python3 -c "
import sys
sys.path.insert(0, '/root/autofix-pro-digital-ocean-code/DoneEZ')
try:
    import django
    print('Django import successful')
    from django.core.management import execute_from_command_line
    print('Django management import successful')
except ImportError as e:
    print(f'Django import failed: {e}')
"
else
    echo "Django manage.py not found in expected location"
fi
echo ""

echo "9. Checking frontend build status..."
cd /root/autofix-pro-digital-ocean-code/fr
if [ -f "package.json" ]; then
    echo "Frontend project found. Checking build..."
    if [ -d ".next" ]; then
        echo "Next.js build directory exists"
    else
        echo "Next.js build directory missing - this could be the issue!"
    fi
else
    echo "Frontend package.json not found"
fi
echo ""

echo "10. Attempting to restart services..."
echo "Stopping PM2 processes..."
pm2 stop all
pm2 delete all
echo ""

echo "Starting backend..."
cd /root/autofix-pro-digital-ocean-code/DoneEZ
pm2 start "python3 manage.py runserver 0.0.0.0:8000" --name "doneez-backend"
echo ""

echo "Starting frontend..."
cd /root/autofix-pro-digital-ocean-code/fr
pm2 start "npm start" --name "doneez-frontend"
echo ""

echo "Saving PM2 configuration..."
pm2 save
echo ""

echo "Reloading nginx..."
sudo nginx -s reload
echo ""

echo "11. Final status check..."
sleep 5
pm2 list
echo ""

echo "Testing services again..."
echo "Frontend test:"
curl -I http://localhost:3000 2>/dev/null || echo "Frontend still not responding"
echo "Backend test:"
curl -I http://localhost:8000 2>/dev/null || echo "Backend still not responding"
echo ""

echo "=== Debug script completed ==="
echo "If services are still not working, check the PM2 logs with: pm2 logs"