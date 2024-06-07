#!/bin/bash

function generate_angular_project {
  ng new client --skip-git --style=scss --routing
  cd client || exit
  install_client_dependencies
  setup_styles
  cd ..
}

function install_client_dependencies {
  npm install --save @types/node @types/uuid
  npm install --save @swimlane/ngx-charts d3 @angular/animations rxjs
  npm install --save-dev tailwindcss postcss autoprefixer
  npm install --save tailwind-scrollbar-hide
  npm install --save @fortawesome/angular-fontawesome @fortawesome/fontawesome-svg-core
  npm install --save @fortawesome/free-brands-svg-icons @fortawesome/pro-solid-svg-icons
  npm install --save @fortawesome/pro-regular-svg-icons @fortawesome/pro-light-svg-icons
  npm install --save @fortawesome/pro-thin-svg-icons @fortawesome/pro-duotone-svg-icons
  npm install --save @fortawesome/sharp-solid-svg-icons @fortawesome/sharp-regular-svg-icons
  npm install --save @fortawesome/sharp-light-svg-icons @fortawesome/fontawesome-pro
}

function setup_styles {
  mkdir -p src/styles
  reset_css > src/styles/reset.css
  tailwind_setup
}

function reset_css {
  cat <<EOL
html, body, div, span, applet, object, iframe,
h1, h2, h3, h4, h5, h6, p, blockquote, pre,
a, abbr, acronym, address, big, cite, code,
del, dfn, em, img, ins, kbd, q, s, samp,
small, strike, strong, sub, sup, tt, var,
b, u, i, center,
dl, dt, dd, ol, ul, li,
fieldset, form, label, legend,
table, caption, tbody, tfoot, thead, tr, th, td,
article, aside, canvas, details, embed,
figure, figcaption, footer, header, hgroup,
menu, nav, output, ruby, section, summary,
time, mark, audio, video {
	margin: 0;
	padding: 0;
	border: 0;
	font-size: 100%;
	font: inherit;
	vertical-align: baseline;
}
/* HTML5 display-role reset for older browsers */
article, aside, details, figcaption, figure,
footer, header, hgroup, menu, nav, section {
	display: block;
}
body {
	line-height: 1;
}
ol, ul {
	list-style: none;
}
blockquote, q {
	quotes: none;
}
blockquote:before, blockquote:after,
q:before, q:after {
	content: '';
	content: none;
}
table {
	border-collapse: collapse;
	border-spacing: 0;
}
EOL
}

function tailwind_setup {
  cat <<EOL > tailwind.config.cjs
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./src/**/*.{html,ts}'],
  theme: {
    extend: {
      fontSize: {
        '1': '1px',
      }
    },
  },
  plugins: [
    require('tailwindcss'),
    require('autoprefixer'),
    require('tailwind-scrollbar-hide')
  ],
}
EOL

  cat <<EOL > src/styles.scss
@import 'tailwindcss/base';
@import 'tailwindcss/components';
@import 'tailwindcss/utilities';
EOL
}

generate_angular_project
