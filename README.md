# Raytracing WebGL
![GitHub Pages Deploy CI](https://github.com/andesyv/RaytracingWebGL/workflows/GitHub%20Pages%20Deploy%20CI/badge.svg)
[![GitHub license](https://img.shields.io/github/license/andesyv/RaytracingWebGL)](https://github.com/andesyv/RaytracingWebGL/blob/master/LICENSE)

A shadertoy raytracing shader hosted using WebGL, Webpack and GitHub pages.
Check out the result: [andesyv.github.io/RaytracingWebGL/](https://andesyv.github.io/RaytracingWebGL/)

## Testing environment
If you want to test out the result yourself or setup a coding environment, do the following:

### Building
`Node.js` and `yarn`(a node package) is required to build the project.
The project was made using node version 12 but other versions probably work aswell. 
A `package.json` exist with all the details regarding packages and stuff.

If you don't have `yarn` installed, do
```
npm intall -g yarn
```

With `yarn` installed you can then install all project packages with
```
yarn install
```


The `package.json` file includes a script for building the page which can be run with
```
yarn build
```
The script will run `webpack`, which again will run the typescript compiler and package
everything into the `build` folder. The final result can be viewed in the `build/index.html` file.

## License
Project is licensed under a standard [MIT License](LICENSE).
