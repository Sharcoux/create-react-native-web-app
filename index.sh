#!/bin/bash

set -e

npx -v > /dev/null 2>/dev/null || echo "You must install npx with `npm i -g npx`."
perl -v > /dev/null 2>/dev/null || echo "You must install perl with `sudo apt install perl`."
read -p "What is your project display name? " displayName
read -p "What is your project package name? " name

# Init the project
npx react-native init $name
cd $name
git init

# Install all dependencies
npm i -S react-native-web react-dom
npm i -D babel-loader html-loader html-webpack-plugin webpack webpack-cli webpack-dev-server dotenv husky lint-staged

# node dotenv
echo "NODE_ENV=development" > .env

# Save App configuration
echo "{
  \"name\": \"$name\",
  \"displayName\": \"$displayName\"
}" > app.json

# Fix index.js for web
echo "import {AppRegistry, Platform} from 'react-native';
import App from './src';
import {name as appName} from './app.json';

AppRegistry.registerComponent(appName, () => App);

if (Platform.OS === 'web') {
  AppRegistry.runApplication(appName, {
    rootTag: document.getElementsByTagName('body')[0]
  })
}
" > index.js

# Update package scripts
perl -i -0pe 's/"scripts": \{.*?\}/"scripts": {
    "android": "react-native run-android",
    "ios": "react-native run-ios",
    "start": "react-native start",
    "lint": "eslint --fix .",
    "build": "webpack",
    "web": "webpack-dev-server --open --mode development"
  }/sg' ./package.json

# Add husky and lint-staged to run eslint
perl -i -0pe 's/"jest": \{.*?\}/"husky": {
    "hooks": {
      "pre-commit": "lint-staged"
    }
  },
  "lint-staged": {
    "*.js?(x)": ["eslint . --fix", "git add"]
  }/s' ./package.json

# Webpack configuration
echo "const HtmlWebPackPlugin = require('html-webpack-plugin')
const path = require('path')
const { displayName } = require('./app.json')
const result = require('dotenv').config()

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
        use: {
          loader: 'html-loader'
        }
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
rm App.js

# Install typescript if needed
read -p "Do you intend to use typescript for this project? (yN) " useTS
if [ $useTS = 'y' ] || [ $useTS = 'yes' ]
then
  # Change for ts files
  mv index.js index.ts
  perl -i -pe "s/index.js/index.ts/g" webpack.config.js
  mv src/index.js src/index.tsx

  # Create tsconfig.js
  echo '{
  "compilerOptions": {
    /* Basic Options */
    "target": "esnext" /* Specify ECMAScript target version: "ES3" (default), "ES5", "ES2015", "ES2016", "ES2017","ES2018" or "ESNEXT". */,
    "module": "commonjs" /* Specify module code generation: "none", "commonjs", "amd", "system", "umd", "es2015", or "ESNext". */,
    "lib": [
      "esnext",
      "dom"
    ]                                         /* Specify library files to be included in the compilation. */,
    // "allowJs": true,                       /* Allow javascript files to be compiled. */
    // "checkJs": true,                       /* Report errors in .js files. */
    "jsx": "react"                            /* Specify JSX code generation: "preserve", "react-native", or "react". */,
    // "declaration": true,                   /* Generates corresponding ".d.ts" file. */
    // "declarationMap": true,                /* Generates a sourcemap for each corresponding ".d.ts" file. */
    // "sourceMap": true,                     /* Generates corresponding ".map" file. */
    // "outFile": "./",                       /* Concatenate and emit output to single file. */
    // "outDir": "./dist/",                   /* Redirect output structure to the directory. */
    // "rootDir": "./",                       /* Specify the root directory of input files. Use to control the output directory structure with --outDir. */
    // "composite": true,                     /* Enable project compilation */
    // "removeComments": true,                /* Do not emit comments to output. */
    "noEmit": false                           /* Do not emit outputs. */,
    // "importHelpers": true                  /* Import emit helpers from "tslib". */,
    // "downlevelIteration": true,            /* Provide full support for iterables in "for-of", spread, and destructuring when targeting "ES5" or "ES3". */
    // "isolatedModules": true,               /* Transpile each file as a separate module (similar to "ts.transpileModule"). */
    /* Strict Type-Checking Options */
    "strict": true                            /* Enable all strict type-checking options. */,
    // "noImplicitAny": true,                 /* Raise error on expressions and declarations with an implied "any" type. */
    // "strictNullChecks": true,              /* Enable strict null checks. */
    // "strictFunctionTypes": true,           /* Enable strict checking of function types. */
    // "strictBindCallApply": true,           /* Enable strict "bind", "call", and "apply" methods on functions. */
    // "strictPropertyInitialization": true,  /* Enable strict checking of property initialization in classes. */
    // "noImplicitThis": true,                /* Raise error on "this" expressions with an implied "any" type. */
    // "alwaysStrict": true,                  /* Parse in strict mode and emit "use strict" for each source file. */
    /* Additional Checks */
    "noUnusedLocals": true                    /* Report errors on unused locals. */,
    "noUnusedParameters": true                /* Report errors on unused parameters. */,
    // "noImplicitReturns": true,             /* Report error when not all code paths in function return a value. */
    // "noFallthroughCasesInSwitch": true,    /* Report errors for fallthrough cases in switch statement. */
    /* Module Resolution Options */
    "moduleResolution": "node"                /* Specify module resolution strategy: "node" (Node.js) or "classic" (TypeScript pre-1.6). */,
    // "baseUrl": "./",                       /* Base directory to resolve non-absolute module names. */
    // "paths": {},                           /* A series of entries which re-map imports to lookup locations relative to the "baseUrl". */
    // "rootDirs": [],                        /* List of root folders whose combined content represents the structure of the project at runtime. */
    // "typeRoots": [],                       /* List of folders to include type definitions from. */
    // "types": [],                           /* Type declaration files to be included in compilation. */
    "allowSyntheticDefaultImports": true      /* Allow default imports from modules with no default export. This does not affect code emit, just typechecking. */,
    "esModuleInterop": true                   /* Enables emit interoperability between CommonJS and ES Modules via creation of namespace objects for all imports. Implies "allowSyntheticDefaultImports". */,
    // "preserveSymlinks": true,              /* Do not resolve the real path of symlinks. */
    /* Source Map Options */
    // "sourceRoot": "",                      /* Specify the location where debugger should locate TypeScript files instead of source locations. */
    // "mapRoot": "",                         /* Specify the location where debugger should locate map files instead of generated locations. */
    // "inlineSourceMap": true,               /* Emit a single file with source maps instead of having a separate file. */
    // "inlineSources": true,                 /* Emit the source alongside the sourcemaps within a single file; requires "--inlineSourceMap" or "--sourceMap" to be set. */
    /* Experimental Options */
    // "experimentalDecorators": true,        /* Enables experimental support for ES7 decorators. */
    // "emitDecoratorMetadata": true,         /* Enables experimental support for emitting type metadata for decorators. */
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true
  },
  "exclude": ["node_modules"]
}' > tsconfig.json

  # Install typescript dependencies
  npm i -D typescript @types/react @types/react-native react-native-typescript-transformer ts-loader @typescript-eslint/parser @typescript-eslint/eslint-plugin

  # Update webpack config for ts files
  perl -i -0pe "s#rules: \[.*?\]#rules: [
      {
        test: /\\\.(tsx|ts|jsx|js|mjs)\\$/,
        exclude: /node_modules/,
        loader: 'ts-loader'
      },
      {
        test: /\\\.(js|jsx)\\$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader'
        }
      },
      {
        test: /\\\.html\\$/,
        use: {
          loader: 'html-loader'
        }
      }
    ]#s" ./webpack.config.js
  perl -i -0pe "s/extensions: \[.*?\]/extensions: [
      '.web.tsx',
      '.web.ts',
      '.tsx',
      '.ts',
      '.web.jsx',
      '.web.js',
      '.jsx',
      '.js'
    ]/s" ./webpack.config.js

  # Setup the project for being a module
  read -p "Will this project be imported as a node module? (yN) " isModule
  if [ $isModule = 'y' ] || [ $isModule = 'yes' ]
  then
    # Add typescript precompiling
    perl -i -0pe 's/"scripts": \{/"scripts": {
    "prepare": "tsc",/sg' ./package.json

    # Fix entry point in package.json
    perl -i -0pe "s#\{(.*)
\}#{\$1,
  \"main\": \"src/index.tsx\",
  \"types\": \"dist/index.d.ts\"
}#sg" ./package.json

    
    # Fix Webpack config
    perl -i -0pe "s/'dist'/'demo'/sg" ./webpack.config.js

    # Fix ts config
    perl -i -0pe 's#// "outDir"#"outDir"#sg' ./tsconfig.json
    perl -i -0pe 's#// "declaration"#"declaration"#sg' ./tsconfig.json
    perl -i -0pe "s#\{(.*)\"exclude\"(.*)\}#{\$1\"include\": [\"src/**/*\"],
  \"exclude\": [\"node_modules\", \"dist\", \"demo\"]
}#s" ./tsconfig.json

    # Ignore demo folder
    echo "demo/" >> ./.gitignore
  fi

fi

# Install storybook if needed
read -p "Do you intend to use storybook for this project? (yN) " useStorybook
if [ $useStorybook = 'y' ] || [ $useStorybook = 'yes' ]
then
  npm i -D @storybook/react
  mkdir stories
  mkdir .storybook

  # Add test script within package.json
  perl -i -0pe 's/"scripts": \{/"scripts": {
    "build-storybook": "build-storybook",
    "storybook": "start-storybook -p 6006",/sg' ./package.json

  # Create the main file
  if [ $useTS = 'y' ] || [ $useTS = 'yes' ]
  then
    # We need to strip typescript off from the files with babel
    npm i -D @babel/preset-typescript

    # Load the files with babel
    echo "module.exports = {
  stories: ['../stories/**/*.stories.js'],
  webpackFinal: async (config) => {

    // Make whatever fine-grained changes you need
    config.module.rules.push({
      test: /\.(tsx|ts|js|jsx)$/,
      exclude: /node_modules/,
      use: {
        loader: 'babel-loader',
        options: { presets: ['@babel/preset-typescript'] }
      }
    });
    config.resolve.extensions = [
      '.web.tsx',
      '.web.ts',
      '.tsx',
      '.ts',
      '.web.jsx',
      '.web.js',
      '.jsx',
      '.js'
    ]
    config.resolve.alias = {
      'react-native$': 'react-native-web'
    }

    // Return the altered config
    return config;
  },
};
" > .storybook/main.js
  else
    echo "module.exports = {
  stories: ['../stories/**/*.stories.js']
}
" > .storybook/main.js
  fi
fi

# Install jest if needed
read -p "Do you intend to use jest for this project? (yN) " useJest
if [ $useJest = 'y' ] || [ $useJest = 'yes' ]
then
  npm i -D jest babel-jest ts-jest eslint-plugin-jest @types/jest
  mkdir tests

  # Add test script within package.json
  perl -i -0pe 's/"scripts": \{/"scripts": {
    "test": "jest",/sg' ./package.json
else
  npm remove jest babel-jest
fi

# Setup eslint
rm .eslintrc.js
npx eslint --init

# Add jest to eslint
if [ $useJest = 'y' ] || [ $useJest = 'yes' ]
then
  perl -i -0pe "s/plugins: \[(.*?)
  \]/plugins: [\$1,
    'jest'
  ]/sg" ./.eslintrc.js
  perl -i -0pe "s#extends: \[(.*?)
  \]#extends: [\$1,
    'plugin:jest/recommended'
  ]#sg" ./.eslintrc.js
fi

# Add typescript to eslint
if [ $useTS = 'y' ] || [ $useTS = 'yes' ]
then
  # Update eslint for ts files
  perl -i -0pe "s#extends: \[(.*?)
  \]#extends: [\$1,
    'plugin:\@typescript-eslint/eslint-recommended',
    'plugin:\@typescript-eslint/recommended'
  ]#sg" ./.eslintrc.js
fi    


rm -rf __tests__
rm .flowconfig
rm .prettierrc.js
