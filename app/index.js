// Generated by CoffeeScript 1.7.1
(function() {
  var Vis, font_loaded, test, vis;

  test = require("./test");

  Vis = require("./vis2");

  vis = new Vis();

  font_loaded = new Promise(function(resolve) {
    vis.animate();
    return require('./load')({
      font: 'fnt/DejaVu-sdf.fnt',
      image: 'fnt/DejaVu-sdf.png'
    }, function(font, texture) {
      return resolve({
        font: font,
        texture: texture
      });
    });
  });

  font_loaded.then(function(obj) {
    vis.setTexture(obj.texture);
    vis.setFont(obj.font);
    return vis.tempAddText("foo bar");
  });

  console.log("hello from app");

}).call(this);