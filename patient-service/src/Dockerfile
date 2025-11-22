# FROM node:lts-slim AS build
# WORKDIR /app
# COPY package*.json ./
# RUN npm install

FROM node:lts-slim
WORKDIR /usr/src/app
COPY  package.json .
COPY index.js .
RUN npm install
EXPOSE 3000
CMD [ "npm", "start" ]