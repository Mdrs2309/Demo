### STAGE 1: Build ###
FROM node:12.2.0 as build
LABEL stage=intermediate

# set working directory
WORKDIR /usr/src/app

# install chrome for protractor tests
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
RUN apt-get update && apt-get install -yq google-chrome-stable

# add `/app/node_modules/.bin` to $PATH
ENV PATH /app/node_modules/.bin:$PATH

# install and cache app dependencies
COPY package.json package-lock.json ./
RUN npm install
RUN npm install -g @angular/cli@9.1.11
RUN npm install sonar-scanner --save-dev
RUN npm install karma-sonarqube-unit-reporter --save-dev
COPY . .

# Run lint & tests
RUN ng lint

# RUN ng test --watch=false --code-coverage
# RUN npm run sonar

# Packaging the Code 
RUN ng build --prod --configuration production
    
### STAGE 2: Run ###
FROM nginx:1.21.5-alpine
COPY nginx.conf /etc/nginx/nginx.conf
COPY ssl.key /usr/share/ssl.key
COPY sslhost.crt /usr/share/sslhost.crt
COPY --from=build /usr/src/app/dist/atop-drt-ui /usr/share/nginx/html

# When the container starts, replace the env.js with values from environment variables
CMD ["/bin/sh",  "-c",  "envsubst < /usr/share/nginx/html/assets/env.template.js > /usr/share/nginx/html/assets/env.js && exec nginx -g 'daemon off;'"]
