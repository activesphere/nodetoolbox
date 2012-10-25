module.exports = production =   {
  name: "toolbox",
  hosts : [{host: "toolbox-new", location:"~/apps/nodetoolbox"}],
  repository: { type: "git", url: "git://github.com/sreeix/nodetoolbox2.git", branch: "master"},
  deploymentType: "npm",
  pre_deploy: function setupfolders (done) {
    console.log("pre deploy");
    done();
  },
  post_deploy: function cleanup (done) {
    return this.cleanup(done);
  }
};