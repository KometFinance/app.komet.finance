import '@webcomponents/custom-elements' // that's our polyfill
import '@webcomponents/webcomponentsjs/webcomponents-loader.js'
import '@webcomponents/webcomponentsjs/custom-elements-es5-adapter.js'

const markup = `
  <svg class="electric-loader" viewBox="0 0 100 100">
      <defs>
          <filter id="goo">
              <feGaussianBlur in="SourceGraphic" stdDeviation="4" result="blur" />
              <feColorMatrix
                  in="blur"
                  mode="matrix"
                  values="1 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 17 -2.15"
                  result="goo"
              />
              <feComposite in="SourceGraphic" in2="goo" operator="over" />
          </filter>
      </defs>
      <g filter="url(#goo)"></g>
  </svg>
`

const svgns = 'http://www.w3.org/2000/svg'
const twoPI = Math.PI * 2

function ElectricLine (radius = 48, startOffset = 0) {
  const path = document.createElementNS(svgns, 'path')

  const coords = []
  const centerX = 50
  const centerY = 50

  for (let i = 0; i <= twoPI + 0.1; i += 0.1) {
    coords.push(centerX + Math.sin(i + startOffset) * radius, centerY + Math.cos(i + startOffset) * radius)
  }

  // Slightly randomize the points
  function updateElectricLine () {
    path.setAttribute(
      'd',
      coords
        .map((point, i) => {
          return (
            (i === 0 ? 'M' : i % 2 === 0 ? 'L' : ',') + Math.round((point + Math.random() * 3) * 100) / 100
          )
        })
        .join('')
    )
  }

  path.style.animationDelay = '0s, ' + -Math.random() + 's'
  // path.style.animationDuration = (1.5 + Math.random()) + 's, ' + 0.2 + ( Math.random() * 0.4 ) + 's';

  updateElectricLine()

  // Have to get it in the dom for `getTotalLength` to work
  const tempSVG = document.createElementNS(svgns, 'svg')
  tempSVG.appendChild(path)
  document.body.appendChild(tempSVG)

  // Get the line length
  const length = path.getTotalLength()
  document.body.removeChild(tempSVG)

  // Set an accurate strokeDasharray & offset for the animation
  path.style.strokeDasharray = `${length / 2}` // ( length * 0.48 ) + ' ' + ( length * 0.52 );
  path.style.strokeDashoffset = `${-length}`

  return {
    el: path,
    update: updateElectricLine
  }
}

const lines = [
  new ElectricLine(35, Math.PI * 0.0),
  new ElectricLine(34.5, Math.PI * 1.0),
  new ElectricLine(34, Math.PI * 0.25),
  new ElectricLine(33.5, Math.PI * 1.25),
  new ElectricLine(33, Math.PI * 0.5),
  new ElectricLine(32.5, Math.PI * 1.5)
]

export class Plasma extends HTMLElement {
  connectedCallback () {
    this.innerHTML = markup
    const svg = document.querySelector('.electric-loader g')
    lines.forEach(line => svg.appendChild(line.el))

    // let t = 0
    // function update () {
    // requestAnimationFrame(update)
    // if (t % 7 === 0) {
    // lines.forEach(line => {
    // line.update()
    // })
    // }
    // t++
    // }

    // update()
  }

  disconnectedCallback () {}
}

// the last important step here: registering our element so people can actually use it in their HTML
customElements.define('plasma-reward', Plasma)
