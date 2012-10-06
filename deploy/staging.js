module.exports = staging =   {
  hosts : [{host: "192.168.0.105", user: "v", location:"~/apps/nodetoolbox"}],
  repository: "git://github.com/sreeix/nodetoolbox2.git",
  branch: "master",
  deploymentType: "npm",
  predeploy: function setupfolders (done) {
    console.log("pre deploy");
    done("predeploy");
  },
  postdeploy: function cleanup (done) {
    console.log("Post deploy")
    done("postdeploy");
  }
};