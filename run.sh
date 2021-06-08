#!/bin/sh

# shellcheck disable=SC2034 # used to configure rover
APOLLO_TELEMETRY_DISABLED=1

ERROR_LOG="/tmp/rover-errors.log"
PUBLISH_LOG="/tmp/rover-publish.log"
SUBGRAPH_SCHEMA_FILE="/tmp/subgraph-schema.graphql"

ROVER_SUBGRAPH_ENDPOINT=${ROVER_SUBGRAPH_ENDPOINT:?}
ROVER_SUBGRAPH_NAME=${ROVER_SUBGRAPH_NAME:?}
ROVER_SUBGRAPH_ROUTING_URL=${ROVER_SUBGRAPH_ROUTING_URL:=$ROVER_SUBGRAPH_ENDPOINT}
ROVER_SUPERGRAPH_NAME=${ROVER_SUPERGRAPH_NAME:?}
ROVER_SUPERGRAPH_VARIANT=${ROVER_SUPERGRAPH_VARIANT:?}

_log() {
  LOG_LEVEL=$1
  LOG_MSG=$2
  LOG_ADDITIONAL_FIELDS=${3:+", $3"}

  echo "{\"level\":\"${LOG_LEVEL}\", \"msg\":\"${LOG_MSG}\", \"time\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\", \"version\": \"${VERSION}\", \"name\": \"apollo-federated-subgraph-publish\", \"subgraphEndpoint\": \"${ROVER_SUBGRAPH_ENDPOINT}\", \"subgraphName\":\"${ROVER_SUBGRAPH_NAME}\", \"subgraphRoutingURL\":\"\", \"supergraphName\": \"${ROVER_SUPERGRAPH_NAME}\", \"supergraphVariant\": \"${ROVER_SUPERGRAPH_VARIANT}\" ${LOG_ADDITIONAL_FIELDS}}"
}

set -- ./rover subgraph introspect "$ROVER_SUBGRAPH_ENDPOINT"
if [ -n "$ROVER_SUBGRAPH_HEADERS" ]; then
    set -- "$@" "$ROVER_SUBGRAPH_HEADERS"
elif [ -n "$ROVER_SUBGRAPH_BEARER_TOKEN" ]; then
    set -- "$@" --header "Authorization: Bearer ${ROVER_SUBGRAPH_BEARER_TOKEN}"
fi

_log "info" "enhanced introspection starting"
"$@" > $SUBGRAPH_SCHEMA_FILE 2>$ERROR_LOG

if [ -s $SUBGRAPH_SCHEMA_FILE ]; then
    _log "info" "enhanced introspection completed" "\"schema\": \"$(cat ${SUBGRAPH_SCHEMA_FILE})\""
    _log "info" "Publishing ${ROVER_SUBGRAPH_NAME} with routing URL ${ROVER_SUBGRAPH_ROUTING_URL}"
    ./rover subgraph publish "${ROVER_SUPERGRAPH_NAME}@${ROVER_SUPERGRAPH_VARIANT}" \
        --name "$ROVER_SUBGRAPH_NAME" \
        --routing-url "$ROVER_SUBGRAPH_ROUTING_URL" \
        --schema "$SUBGRAPH_SCHEMA_FILE" \
        >"$PUBLISH_LOG" 2>&1
    _log "info" "$(cat ${PUBLISH_LOG})"
else
    _log "error" "error: no schema fetched - publishing aborted" "\"error\": \"$(cat ${ERROR_LOG})\""
    exit 1
fi
