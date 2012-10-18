module.exports = production =   {
  hosts : [{host: "toolbox-new", location:"~/apps/nodetoolbox"}],
  repository: { type: "git", url: "git://github.com/sreeix/nodetoolbox2.git", branch: "deployment"},
  deploymentType: "npm",
  pre_deploy: function setupfolders (done) {
    console.log("pre deploy");
    done()
  },
  post_deploy: function cleanup (done) {
    console.log("Post deploy")
    done();
  }
};