# Deployment Guide: DRF Backend and Next.js 14.2 Frontend on Ubuntu Server with SSL

[Previous content remains the same]

## 6. Update Application Configurations for HTTPS

[Previous content for Django settings remains the same]

2. Update your Next.js configuration and Axios setup:

   a. In your Next.js project, create or update an API configuration file (e.g., `config/axios.js`):

   ```javascript
   import axios from 'axios';

   const baseURL = process.env.NEXT_PUBLIC_API_URL || 'https://your-server-domain.com/api';

   const axiosInstance = axios.create({
     baseURL: baseURL,
     timeout: 5000,
     headers: {
       'Content-Type': 'application/json',
       'Accept': 'application/json'
     }
   });

   export default axiosInstance;
   ```

   b. Update your Next.js configuration (next.config.js):

   ```javascript
   module.exports = {
     reactStrictMode: true,
     env: {
       NEXT_PUBLIC_API_URL: process.env.NODE_ENV === 'production'
         ? 'https://your-server-domain.com/api'
         : 'http://localhost:8000/api',
     },
   }
   ```

   c. In your components or pages where you make API calls, import and use the Axios instance:

   ```javascript
   import api from '../config/axios';

   // Example API call
   const fetchData = async () => {
     try {
       const response = await api.get('/some-endpoint');
       // Handle the response
     } catch (error) {
       // Handle any errors
     }
   };
   ```

3. Update your .env.local file for local development:

   ```
   NEXT_PUBLIC_API_URL=http://localhost:8000/api
   ```

   Note: Don't commit this file to version control.

4. On your production server, set the environment variable:

   ```bash
   echo "NEXT_PUBLIC_API_URL=https://your-server-domain.com/api" >> .env.local
   ```

5. Rebuild your Next.js application:

   ```bash
   npm run build
   ```

6. Restart your Next.js application:

   ```bash
   pm2 restart nextjs
   ```

Remember to replace `your-server-domain.com` with your actual server domain throughout the configuration.

## Additional Notes

1. Ensure all internal API calls in your Next.js app now use the Axios instance you've configured.
2. The Axios configuration allows for easy switching between development and production environments.
3. If you're using WebSockets, make sure to update the protocols to WSS.
4. Regularly check for SSL certificate renewals and keep your server updated.
5. Consider implementing HTTP Strict Transport Security (HSTS) for enhanced security.
6. If your API requires authentication, you may need to configure Axios to include authentication tokens in requests.