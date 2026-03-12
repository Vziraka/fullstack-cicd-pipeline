# what does this do ?
# used to create a docker image for the applications 
# we use a multi-stage design one is too build it so install the dependencies like (express and uuid)
# second stage copy the dependencies and the source code to a new image and run it 




# builder stage 
FROM node:24-alpine AS builder
# use tells to use node.js version 
WORKDIR /app
# tells where the app is located 
COPY app/package*.json ./
# copy all the app pakaged code into the docker image 
RUN npm ci --only=production
# take the copy and intall all "PRODUCTION" dependecies so not nodemon 





# prodcutions stage 
FROM node:24-alpine AS production
# tells what node.js version were using 
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
# this creates a non-root by adding user group called system and adds a user to it  
WORKDIR /app

COPY --from=builder /app/node_modules ./node_modules
COPY app/ .
# Copies ONLY the node_modules folder from the builder stage 
# into the production image. This is the whole point of multi-stage — 
# we leave the build tools behind and only take what we need to run the app.
RUN chown -R appuser:appgroup /app
# Gives the appuser ownership of all files in /app. 
# Without this the files would be owned by root and appuser couldn't read them.
USER appuser
# switches from root to user
EXPOSE 3000
# this is the port its gonna run on 
CMD ["node", "server.js"]
# tells docker wehn user run image run node first then the server.js file 