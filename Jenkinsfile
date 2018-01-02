node ('sl6') {
  def workspace = pwd()
  withEnv(["GEM_HOME=${workspace}", "PATH=${workspace}/bin:$PATH"]) {
    try {
      git poll:true, url: 'https://github.com/slconley/puppet-redmine.git'
      stage 'Build Setup'
      sh 'gem install bundler'
      sh 'bundle install --deployment'

      stage 'Lint'
      sh 'bundle exec rake lint'

      stage 'Validate'
      sh 'bundle exec rake validate'

      stage 'Spec'
      sh 'bundle exec rake spec || true'

      stage 'Build'
      sh 'bundle exec rake build'

      notifySuccessful()
    } catch (err) {
      currentBuild.result = 'FAILURE'
      notifyFailed()
      throw err
    } // try
  } // withEnv
} // node
def notifyStarted() { /* .. */ }

def notifySuccessful() {
  //build job: 'DevOps-InfraAsCode/Puppet-Control/Control_test', wait: false
}

def notifyFailed() {
  //step([$class: 'Mailer', recipients: 'gshepherd@solidyn.com'])
  //slackSend (color: '#FF0000', message: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
}
