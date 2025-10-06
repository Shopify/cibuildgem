const easyCompile = require('../src/index');

describe('index.js', () => {
  test('when workflow pass a working_directory variable', async () => {
    let foo = await easyCompile.run();

    console.log(foo)
  })
})
