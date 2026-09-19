FROM quay.io/keycloak/keycloak:26.7.4 as builder
###
# Στο σημείο αυτό θα παραμετροποιήσω το keycloak image χρησιμοποιώντας build options (βλέπε σχόλιο παρακάτω)
# Enable health and metrics support
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true
# Configure a database vendor
ENV KC_DB=postgres

WORKDIR /opt/keycloak
# for demonstration purposes only, please make sure to use proper certificates in production instead
# In production mode sssl termination is handeled by reverse proxy
#RUN keytool -genkeypair -storepass password -storetype PKCS12 -keyalg RSA -keysize 2048 -dname "CN=server" -alias server -ext "SAN:c=DNS:localhost,IP:127.0.0.1" -keystore conf/server.keystore

###
# **Creating an optimized Keycloak build**
# By default, when you use the start or start-dev command, Keycloak runs a build command under the covers for convenience reasons.
# This build command performs a set of optimizations for the startup and runtime behavior. The build process can take a few seconds. 
# Especially when running Keycloak in containerized environments such as Kubernetes or OpenShift, startup time is important. 
# To avoid losing that time, run a build explicitly before starting up, such as a separate step in a CI/CD pipeline.
# Πρέπει να ξέρω ποιά είναι τα Build Options και ποιά τα runtime Configuration Options (βλέπε https://www.keycloak.org/server/all-config)
# Οπότε η "καλή πρακτική" είναι να θέτω όλα τα build options εδώ και να δημιουργώ ένα optimized keycloak image
# Έτσι, όταν ξεκινάμε το keycloak χρησιμοποιούμε την παράμετρο --optimized
# The --optimized parameter tells Keycloak to assume a pre-built, already optimized Keycloak image is used. 
# As a result, Keycloak avoids checking for and running a build directly at startup, which saves time.
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:26.7.4
COPY --from=builder /opt/keycloak/ /opt/keycloak/

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]