#!/bin/bash

set -e

npx -v > /dev/null 2>/dev/null || echo "You must install npx with `npm i -g npx`."
perl -v > /dev/null 2>/dev/null || echo "You must install perl with `sudo apt install perl`."
read -p "What is your project display name?" displayName
read -p "What is your project package name?" name

# Init the project
npx react-native init $name
cd $name

# Install all dependencies
npm i -D babel-loader html-loader html-webpack-plugin webpack webpack-cli webpack-dev-server react-dom react-native-web dotenv

# Setup eslint
rm .eslintrc.js
npx eslint --init

# node dotenv
echo "NODE_ENV=development" > .env

# Save App configuration
echo "{
  name: $name,
  displayName: $displayName
}" > app.json

# Fix index.js for web
echo "
if (Platform.OS === 'web') {
  AppRegistry.runApplication(appName, {
    rootTag: document.getElementsByTagName('body')[0]
  })
}
" >> index.js

# Update package scripts
perl -i -0pe 's/"dependencies": \{.*\}/"scripts": {
    "android": "react-native run-android",
    "ios": "react-native run-ios",
    "start": "react-native start",
    "lint": "eslint .",
    "build": "webpack",
    "web": "webpack-dev-server --open --mode development"
  }/s' ./package.json

# Webpack configuration
echo "const HtmlWebPackPlugin = require('html-webpack-plugin')
const path = require('path')
const { displayName } = require('./app.json')
const result = dotenv.config()
 
if (result.error) {
  throw result.error
}

module.exports = {
  mode: process.env.NODE_ENV || 'development',
  entry: {
    app: path.resolve(__dirname, 'index.js')
  },
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: 'index.bundle.js'
  },
  devtool: 'source-map',
  devServer: {
    contentBase: path.resolve(__dirname, 'dist'),
    compress: true,
    port: 9000
  },
  module: {
    rules: [
      {
        test: /\.(js|jsx)$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader'
        }
      },
      {
        test: /\.html$/,
        use: [
          {
            loader: 'html-loader'
          }
        ]
      }
    ]
  },
  plugins: [
    new HtmlWebPackPlugin({ title: displayName })
  ],
  resolve: {
    extensions: ['.web.js', '.js'], // read files in fillowing order
    alias: Object.assign({
      'react-native$': 'react-native-web'
    })
  }
}
" > webpack.config.js

# Add dist to gitignore
echo "dist/" >> .gitignore

# Create dummy app
mkdir src
echo "import React from 'react'
import {
  View,
  Text
} from 'react-native'

const App = () => {
  return (
    <View>
      <Text>Welcome to $displayName</Text>
    </View>
  )
}

export default App
" > src/index.js