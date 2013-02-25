module.exports = staging =   {
  name: 'toolbox',
  hosts : [{host: "192.168.2.38", user: "v", location:"~/apps/nodetoolbox"}],
  repository: { type: "git", url: "git://github.com/sreeix/nodetoolbox2.git", branch: "master"},
  deploymentType: "npm",
  predeploy: function setupfolders (done) {
    console.log("pre deploy");
    done();
  },
  postdeploy: function cleanup (done) {
    console.log("Post deploy")
    this.cleanup(done);
  }
};