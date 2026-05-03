set -euo pipefail
source "$(dirname "$0")/config.sh"


DEPLOYMENT_PREFIX="-deployment-"
SERVICE_PREFIX="-service-"


DBWRAPPER_NAME="database-wrapper"
MATCHMAKING="matchmaking"


DBWRAPPER_DEPLOYMENT_NAME="$RELEASE_NAME$DEPLOYMENT_PREFIX$DBWRAPPER_NAME"
MATCHMAKING_DEPLOYMENT_NAME="$RELEASE_NAME$DEPLOYMENT_PREFIX$MATCHMAKING"


echo ">>> Restarting DBWrapper deployment..."
sudo kubectl rollout restart deployment $DBWRAPPER_DEPLOYMENT_NAME -n $NAMESPACE

echo ">>> Restarting Matchmaking deployment..."
sudo kubectl rollout restart deployment $MATCHMAKING_DEPLOYMENT_NAME -n $NAMESPACE