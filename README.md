# BLT Best Deployment

Example K8s deployment that does automated rollback.

## The project

This project is a very simple node application.
In order to avoid building a docker artifact the
index.js is inside of our configmap
[infra/deployment-cm.yaml](infra/deployment-cm.yaml)

The index.js will return 500 if the env var
`FAIL_REQUEST` is set to true.

## Ensuring readiness

First, in order to do this it is important that
your application has valid __readinessProbes__ attached
to it.  We don't want Kubernetes to think the deployment
was successful because your container takes a second
to load and realize it's failing.

## Verifying deployment

With your __readinessProbe__ equiped, we can then use
the `kubectl rollout status` command to watch the deployment.

By default, status will watch the status and exit upon
successful completion.  Since it's hard to tell what
a failure is, we rely on timing out using `timeout`.
In this example we wait for 5 mins.

## Conclusion

With our rollout status check as a target step in our
[Makefile](Makefile), the error will propagate up
to our Travis build so we're notified of the
deployment failure.
