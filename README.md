# uptimetoolbox-agent

Linux agent for [uptimetoolbox.com](https://www.uptimetoolbox.com)


### Usage

```
sudo curl -s https://raw.githubusercontent.com/uptimetoolbox/uptimetoolbox-agent/v1.2.1/setup.sh \
 | sudo bash -s -- \
  -n 411c670c-d092-4c7f-985e-777b8900d8fa \
  -t df3048b6-9f3f-47a1-9654-1c37147eabc2 \
  -s http://ingest.syscloak.com
```


## Testing locally

```
sudo bash setup.sh -a master \
  -n 411c670c-d092-4c7f-985e-777b8900d8fa \
  -t df3048b6-9f3f-47a1-9654-1c37147eabc2 \
  -s http://ingest.syscloak.com
```