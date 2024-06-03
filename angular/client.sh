function generate_angular_project {
  ng new client
  install_client_dependencies
  cd client/src || exit
  reset_css
  tailwind_setup
}

function install_client_dependencies {
  npm install --save @types/node
  npm install --save @types/uuid
  npm install @swimlane/ngx-charts --save
  npm install d3 @angular/animations --save
  npm install rxjs
  npm install -D tailwindcss postcss autoprefixer
  npm install tailwind-scrollbar-hide
  npm install @fortawesome/angular-fontawesome
  npm install --save @fortawesome/fontawesome-svg-core
  npm install --save @fortawesome/free-brands-svg-icons
  npm install --save @fortawesome/pro-solid-svg-icons
  npm install --save @fortawesome/pro-regular-svg-icons
  npm install --save @fortawesome/pro-light-svg-icons
  npm install --save @fortawesome/pro-thin-svg-icons
  npm install --save @fortawesome/pro-duotone-svg-icons
  npm install --save @fortawesome/sharp-solid-svg-icons
  npm install --save @fortawesome/sharp-regular-svg-icons
  npm install --save @fortawesome/sharp-light-svg-icons
  npm install --save @fortawesome/fontawesome-pro
}

function create_reset_css {
  touch reset.css
  echo "html, body, div, span, applet, object, iframe,
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
}" >>reset.css
}

function tailwind_setup {
  touch tailwind.config.cjs
  echo "
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./**/*.html'],
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
}" >>tailwind.config.cjs

  cd src || exit
  echo "@import 'tailwindcss/base';
@import 'tailwindcss/components';
@import 'tailwindcss/utilities';
  " >>styles.scss

  cd ../ || exit
}