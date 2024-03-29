import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.jenkins.plugins.sshcredentials.impl.*
import hudson.plugins.sshslaves.*;

println "--> creating SSH credentials"

domain = Domain.global()
store = Jenkins.instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

privateKey = new File('/tmp/id_rsa').getText('UTF-8')
System.out.println "Installing Private Key: $privateKey"

slavesPrivateKey = new BasicSSHUserPrivateKey(
CredentialsScope.GLOBAL,
"jenkins-slaves",
"ec2-user",
new BasicSSHUserPrivateKey.DirectEntryPrivateKeySource(privateKey),
"",
""
)

store.addCredentials(domain, slavesPrivateKey)

/*
managersPrivateKey = new BasicSSHUserPrivateKey(
CredentialsScope.GLOBAL,
"swarm-managers",
"ec2-user",
new BasicSSHUserPrivateKey.DirectEntryPrivateKeySource(privateKey),
"",
""
)

githubCredentials = new UsernamePasswordCredentialsImpl(
  CredentialsScope.GLOBAL,
  "github", "Github credentials",
  "admin",
  "admin"
)

registryCredentials = new UsernamePasswordCredentialsImpl(
  CredentialsScope.GLOBAL,
  "registry", "Docker Registry credentials",
  "admin",
  "admin"
)

store.addCredentials(domain, managersPrivateKey)
store.addCredentials(domain, githubCredentials)
store.addCredentials(domain, registryCredentials)
*/