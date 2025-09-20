# AutoFix Pro - Deployment Guide

## Digital Ocean Deployment Setup

### Prerequisites
- Digital Ocean Droplet: `104.236.4.217`
- SSH Access: `ssh root@104.236.4.217` (Password: `Test@1234`)
- GitHub Repository: `https://github.com/cmishler108/autofix-pro-digital-ocean-code.git`

### GitHub Secrets Configuration

Before the CI/CD pipeline can work, you need to configure these secrets in your GitHub repository:

1. Go to your GitHub repository
2. Navigate to Settings → Secrets and variables → Actions
3. Add the following secrets:

```
DO_HOST=104.236.4.217
DO_USERNAME=root
DO_PASSWORD=Test@1234
```

### Deployment Methods

#### Method 1: Automated CI/CD (Recommended)

The GitHub Actions workflow (`.github/workflows/deploy.yml`) automatically deploys when you push to the `main` branch.

**Setup Steps:**
1. Configure GitHub secrets (see above)
2. Push code to main branch
3. GitHub Actions will automatically deploy

#### Method 2: Manual Deployment

**Initial Setup on Droplet:**
```bash
# SSH into your droplet
ssh root@104.236.4.217

# Run the deployment script
curl -sSL https://raw.githubusercontent.com/cmishler108/autofix-pro-digital-ocean-code/main/deploy.sh | bash
```

**Manual Updates:**
```bash
# SSH into droplet
ssh root@104.236.4.217

# Navigate to app directory
cd /var/www/autofix-pro

# Pull latest changes
git pull origin main

# Update frontend
cd fr
npm ci
npm run build
pm2 restart autofix-pro-frontend

# Update backend (if needed)
cd ../DoneEZ/DoneEZ
source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
pm2 restart autofix-pro-backend
```

#### Method 3: Docker Deployment

**Using Docker Compose:**
```bash
# SSH into droplet
ssh root@104.236.4.217

# Install Docker and Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
apt install docker-compose-plugin

# Clone repository
git clone https://github.com/cmishler108/autofix-pro-digital-ocean-code.git /var/www/autofix-pro
cd /var/www/autofix-pro

# Deploy with Docker
docker compose up -d
```

### Application URLs

After deployment, your application will be available at:
- **Frontend:** http://104.236.4.217
- **Backend API:** http://104.236.4.217/api/
- **Django Admin:** http://104.236.4.217/admin/

### Monitoring and Management

**PM2 Commands:**
```bash
pm2 status                    # Check process status
pm2 logs                      # View all logs
pm2 logs autofix-pro-frontend # Frontend logs
pm2 logs autofix-pro-backend  # Backend logs
pm2 restart all               # Restart all processes
```

**Docker Commands:**
```bash
docker compose ps             # Check container status
docker compose logs           # View logs
docker compose restart       # Restart services
docker compose down           # Stop services
docker compose up -d          # Start services
```

### Troubleshooting

**Common Issues:**

1. **Port conflicts:** Ensure ports 80, 3000, and 8000 are available
2. **Permission issues:** Run commands as root or with sudo
3. **Memory issues:** Ensure droplet has sufficient RAM (minimum 1GB recommended)
4. **Build failures:** Check Node.js and Python versions

**Logs Location:**
- PM2 logs: `~/.pm2/logs/`
- Nginx logs: `/var/log/nginx/`
- Application logs: Check PM2 logs

### Security Considerations

1. **Change default passwords** in production
2. **Setup SSL/TLS** for HTTPS
3. **Configure firewall** properly
4. **Regular security updates**
5. **Use environment variables** for sensitive data

### Environment Variables

Create a `.env` file in the frontend directory:
```env
NEXT_PUBLIC_API_URL=http://104.236.4.217/api
```

Create a `.env` file in the backend directory:
```env
DEBUG=False
ALLOWED_HOSTS=104.236.4.217,localhost
SECRET_KEY=your-secret-key-here
```

### Backup Strategy

1. **Database backups:** Regular Django database dumps
2. **Code backups:** Git repository serves as code backup
3. **Static files:** Backup uploaded media files

For support or issues, check the GitHub repository issues section.