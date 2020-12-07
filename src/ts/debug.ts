const noPrints = () => {}
noPrints.log = (_: any, stuff: any) => stuff

const debug = process.env.NODE_ENV === 'production' ? noPrints : console.log
debug.log = (msg: string, stuff: any) => {
  debug(msg, stuff)
  return stuff
}

export default debug
