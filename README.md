# uptimetoolbox-agent

**Official Agent for [uptimetoolbox.com](https://www.uptimetoolbox.com)**


## Linux Agent

```
sudo curl -s https://raw.githubusercontent.com/uptimetoolbox/uptimetoolbox-agent/v1.3.0/setup.sh \
  | sudo bash -s -- \
  -n 411c670c-d092-4c7f-985e-777b8900d8fa \
  -t df3048b6-9f3f-47a1-9654-1c37147eabc2 \
  -s http://ingest.uptimetoolbox.com
```


### To run a specific version, branch or tag

The following example uses the branch `master`.
```
sudo curl -s https://raw.githubusercontent.com/uptimetoolbox/uptimetoolbox-agent/v1.3.0/setup.sh \
  | sudo bash -s -- \
  -a master \
  -n 411c670c-d092-4c7f-985e-777b8900d8fa \
  -t df3048b6-9f3f-47a1-9654-1c37147eabc2 \
  -s http://ingest.uptimetoolbox.com
```


### To uninstall 

```
sudo curl -s https://raw.githubusercontent.com/uptimetoolbox/uptimetoolbox-agent/master/uninstall.sh | sudo bash
```


## Docker Agent

Note that the docker image will create new nodes on UptimeToolbox as needed.

#### For core functionality
```bash
docker run -it --rm \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /proc/:/host/proc/:ro \
  -e ENDPOINT=https://ingest.uptimetoolbox.com \
  -e ORGANIZATION_ID=2c349800-2a32-44fa-95f5-b63e7675d998 \
  -e API_KEY=4797e685-e389-42f7-a37e-faa367453396 \
  --network host \
  uptimetoolbox/agent:1.0.2
```

#### For more complete disk usage data
```bash
docker run -it --rm \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /:/host/:ro \
  -e ENDPOINT=https://ingest.uptimetoolbox.com \
  -e ORGANIZATION_ID=cda08636-4f8c-4254-b9d0-caad47975d96 \
  -e API_KEY=4797e685-e389-42f7-a37e-faa367453396 \
  --network host \
  uptimetoolbox/agent:1.0.2
```

#### For more complete disk usage data + full host process access
```bash
docker run -it --rm \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /:/host/:ro \
  -e ENDPOINT=https://ingest.uptimetoolbox.com \
  -e ORGANIZATION_ID=cda08636-4f8c-4254-b9d0-caad47975d96 \
  -e API_KEY=4797e685-e389-42f7-a37e-faa367453396 \
  --network host \
  --pid host \
  uptimetoolbox/agent:1.0.2
```

Expert users can also cherry-pick the volumes to mount to the image.  
All mounted block devices will be monitored.  
Mounts `/proc/` and `/var/run/docker.sock` are non-optional.


### Other 

#### Rancher 2.X users

Add the following tolerations to Pod spec

```yaml
tolerations:
- key: "node-role.kubernetes.io/controlplane"
  operator: "Exists"
  effect: "NoSchedule"
- key: "node-role.kubernetes.io/etcd"
  operator: "Exists"
  effect: "NoExecute"
```

