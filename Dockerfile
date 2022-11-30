FROM node:14-alpine  AS build

RUN apk --no-cache add shadow \                                                                   
    gcc \                                                                                         
    musl-dev \                                                                                    
    autoconf \                                                                                    
    automake \                                                                                    
    make \                                                                                        
    libtool \                                                                                     
    nasm \                                                                                        
    tiff \                                                                                        
    jpeg \                                                                                        
    zlib \                                                                                        
    zlib-dev \                                                                                    
    file \                                                                                        
    pkgconf

WORKDIR /app
COPY . .

RUN npm install
RUN npm run-script build

FROM httpd:alpine AS deploy

WORKDIR /usr/local/apache2/htdocs/
RUN rm -rf ./*
COPY --from=build /app/public .

EXPOSE 80