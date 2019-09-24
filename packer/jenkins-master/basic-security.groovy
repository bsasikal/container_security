#!groovy

import jenkins.model.*
import hudson.security.*

println "--> creating local user 'USERNAME'"


def instance = Jenkins.getInstance()

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount('admin','admin')
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
//strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)
instance.save()


/*
def jenkins = Jenkins.getInstance()
if(!(jenkins.getSecurityRealm() instanceof HudsonPrivateSecurityRealm))
    jenkins.setSecurityRealm(new HudsonPrivateSecurityRealm(false))

if(!(jenkins.getAuthorizationStrategy() instanceof GlobalMatrixAuthorizationStrategy))
    jenkins.setAuthorizationStrategy(new GlobalMatrixAuthorizationStrategy())

// create new Jenkins user account
def user = jenkins.getSecurityRealm().createAccount("admin", "admin")
user.save()

jenkins.getAuthorizationStrategy().add(Jenkins.ADMINISTER, "admin")
jenkins.save()

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
jenkins.setAuthorizationStrategy(strategy)
jenkins.save()
*/