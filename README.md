# uptimetoolbox-agent

**Official Agent for [uptimetoolbox.com](https://www.uptimetoolbox.com)**


## Linux Agent

```
sudo curl -s https://raw.githubusercontent.com/uptimetoolbox/uptimetoolbox-agent/v1.3.0/setup.sh \
 | sudo bash -s -- \
  -n 411c670c-d092-4c7f-985e-777b8900d8fa \
  -t df3048b6-9f3f-47a1-9654-1c37147eabc2 \
  -s http://ingest.syscloak.com
```


### Testing locally

```
sudo bash setup.sh -a master \
  -n 411c670c-d092-4c7f-985e-777b8900d8fa \
  -t df3048b6-9f3f-47a1-9654-1c37147eabc2 \
  -s http://ingest.syscloak.com
```


### To uninstall 

```
sudo curl -s https://raw.githubusercontent.com/uptimetoolbox/uptimetoolbox-agent/master/uninstall.sh | sudo bash
```


## Docker Agent

### How to use this Image

#### Build

```bash
docker build -t ut-agent .
```

#### For basic functionality
```bash
docker run -it --rm \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /proc/:/host/proc/:ro \
  -e ENDPOINT=http://127.0.0.1:8000 \
  -e ORGANIZATION_ID=2c349800-2a32-44fa-95f5-b63e7675d998 \
  -e API_KEY=4797e685-e389-42f7-a37e-faa367453396 \
  --network host \
  ut-agent
```

#### For more complete disk usage data
```bash
docker run -it --rm \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /:/host/:ro \
  -e ENDPOINT=http://127.0.0.1:8000 \
  -e ORGANIZATION_ID=cda08636-4f8c-4254-b9d0-caad47975d96 \
  -e API_KEY=4797e685-e389-42f7-a37e-faa367453396 \
  --network host \
  ut-agent
```

Expert users can also cherry-pick the volumes to mount to the image.  
All mounted block devices will be monitored.  
`/proc/` and `/var/run/docker.sock` are mandatory


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
