module.exports = production =   {
  name: "toolbox",
  hosts : [{host: "toolbox-new", location:"~/apps/nodetoolbox"}],
  repository: { type: "git", url: "git://github.com/sreeix/nodetoolbox2.git", branch: "master"},
  deploymentType: "npm",
  predeploy: function setupfolders (done) {
    console.log("pre deploy");
    done();
  },
  postdeploy: function cleanup (done) {
    return this.cleanup(done);
  }
};