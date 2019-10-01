# action-docker-publish
A plugin for [Actions CI](https://github.com/features/actions) to tagging and pushing Docker images with minimal effort

## Configuration

An example configuration of how the plugin should be configured:
```yaml
steps:
  - name: publish
    uses: triptixx/action-docker-publish@master
    with:
      docker_username: docker_username
      docker_password: docker_password
      from: image-name-dev
      repo: user/image-name:optional-tag
      tags: docker_tag,over_docker_tag
    args: '--tags'
```

### Available options
- `docker_username`    docker 'username' for pushing. _required_
- `docker_password`    docker 'password' for pushing. _required_
- `from`               re-tag from this repo. _optional_
- `repo`               tag to this repo/repo to push to. _required_
- `registry`           docker registry of your account. _default: `https://hub.docker.com`_
- `tags`               tag TARGET_IMAGE that refers to SOURCE_IMAGE. _default: `latest`_
