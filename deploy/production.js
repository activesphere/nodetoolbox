module.exports = production =   {
  hosts : [{host: "toolbox-new", location:"~/apps/nodetoolbox"}],
  repository: "git://github.com/sreeix/nodetoolbox2.git",
  branch: "master",
  pre_deploy: function setupfolders (options) {
    console.log("pre deploy");
  },
  post_deploy: function cleanup (options) {
    console.log("Post deploy")
  }
};