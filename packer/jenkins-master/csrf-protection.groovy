#!groovy

import hudson.security.csrf.DefaultCrumbIssuer
import jenkins.model.Jenkins

println "--> enabling CSRF protection"

def instance = Jenkins.instance

//this enables CSRF
//instance.setCrumbIssuer(new DefaultCrumbIssuer(true))

//this disables CSRF
instance.setCrumbIssuer(null)

instance.save()