# OPTIMIND

## Introduction

*OPTIMIND* is a research project within the [Collaborative Research Center 289](https://treatment-expectation.de/en/) titled "Treatment Expectation", funded by the German Research Foundation (DFG). The overarching goal is to understand and harness the power of patient expectations to improve medical treatment outcomes. Specifically, OPTIMIND aims to counteract negative treatment expectations regarding antidepressants and thus improve treatment outcomes through just-in-time adaptive interventions (JITAI). Participants receive daily, individualized feedback tailored to their current expectations.

This repository contains the code for real-time analyses that detect repeatedly exceeded cut-offs and regularly report compliance.

## Setup

The code is deployed on a virtual machine. Currently, an Ubuntu 24.04 image is used via [bwCloud 3](https://www.bw-cloud.org/en/). See [First Steps](https://wiki.bwcloud-os.de) for setup instructions. For fast and smooth operation, 8GB of RAM is recommended.

After creating the virtual machine, all packages should first be updated.

```terminal
sudo apt update
sudo apt upgrade
```

[Julia](https://julialang.org/) can then be installed with the following command.

```terminal
curl -fsSL https://install.julialang.org | sh
```

Additionally, this repository must be cloned.

```terminal
git clone https://github.com/CarlBittendorf/OPTIMIND.git
```

To use the cloned repository, a `secrets.jl` file must be created inside the project directory that contains access data, API keys, etc.

```terminal
touch secrets.jl
nano secrets.jl
```

To have the scripts run automatically at specific times, a corresponding entry must be made in the crontab configuration file. This is opened or created with the following command.

```terminal
crontab -e
```

The following lines run the jitai and compliance scripts.

```plain
0 4 * * 0-6 bash -l -c 'cd /home/ubuntu/OPTIMIND && julia --project scripts/jitai.jl 12'
0 10 * * 0-6 bash -l -c 'cd /home/ubuntu/OPTIMIND && julia --project scripts/jitai.jl 6'
0 11 * * 0-6 bash -l -c 'cd /home/ubuntu/OPTIMIND && julia --project scripts/jitai.jl 1'
0 12 * * 0-6 bash -l -c 'cd /home/ubuntu/OPTIMIND && julia --project scripts/jitai.jl 1'
0 13 * * 0-6 bash -l -c 'cd /home/ubuntu/OPTIMIND && julia --project scripts/jitai.jl 1'
0 14 * * 0-6 bash -l -c 'cd /home/ubuntu/OPTIMIND && julia --project scripts/jitai.jl 1'
0 15 * * 0-6 bash -l -c 'cd /home/ubuntu/OPTIMIND && julia --project scripts/jitai.jl 1'
0 16 * * 0-6 bash -l -c 'cd /home/ubuntu/OPTIMIND && julia --project scripts/jitai.jl 1'
30 6 * * 1 bash -l -c 'cd /home/ubuntu/OPTIMIND && julia --project scripts/compliance.jl'
30 6 * * 3 bash -l -c 'cd /home/ubuntu/OPTIMIND && julia --project scripts/compliance.jl'
30 6 * * 5 bash -l -c 'cd /home/ubuntu/OPTIMIND && julia --project scripts/compliance.jl'
```

To update to the latest version, run

```terminal
git pull
```

in the project directory.

## Acknowledgements

Funded by the Deutsche Forschungsgemeinschaft (DFG, German Research Foundation) – GRK2739/1 – Project Nr. 447089431 – Research Training Group: KD²School – Designing Adaptive Systems for Economic Decisions