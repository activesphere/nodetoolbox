module.exports = staging =   {
  name: 'toolbox',
  hosts : [{host: "192.168.1.134", location:"~/apps/nodetoolbox"}],
  repository: { type: "git", url: "git://github.com/sreeix/nodetoolbox2.git", branch: "master"},
  deploymentType: "npm",
  predeploy: function setupfolders (done) {
    this.logger.info("pre deploy");
    done();
  },
  postdeploy: function cleanup (done) {
    this.logger.info("Post deploy")
    this.cleanup(done);
  }
};