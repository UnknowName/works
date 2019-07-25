# Tools Reference

## migrate_kong

```bash
# Get help
python migrate_kong -h
# Export the kong api to file
python migrate_kong --action export --filename dump.cache --src http://kong-admin.kong-prod:8001
# Import the kong api to Dest
python migrate_kong --action import --filename dump.cache --dest http://kong-admin2.kong-prod:8001
# Migrate Kong api.Will replace host and like moses-dev to moese-test
# Add prefix xyyd.
python migrate_kong --action migrate \
--filename dump.cache \
--host new.host.com \
--profile test \
--prefix xyyd \
--dest http://kong-admin.kong-test:8001
```

## export_shift.sh

```bash
# Export the moses-dev project to moses-prod YAML
sh export_shift.sh moses-dev moses-prod

# Import
oc create --filename moses-prod
```