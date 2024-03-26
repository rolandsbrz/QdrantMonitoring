# Qdrant monitoring instruction
1. Pull Qdrant docker image
`docker pull qdrant/qdrant`
2. Start Qdrant database container
`docker run -d -p 6333:6333 --name <container> qdrant/qdrant`
3. Download sample datafile from [datasets page](https://qdrant.tech/documentation/datasets/#available-datasets)
4. Install gnuplot package to your bash
`brew install gnuplot`
5. Start the script "stats.sh" to monitor resources
* If planning to stop manually: `sh stats.sh <container> <filename>`
* If you want to run it for predefined time: `sh stats.sh <container> <filename> <seconds>`
6. Open local environment [collections page](http://localhost:6333/dashboard#/collections)
7. Create new collection by providing snapshot downloaded in step 3
8. Wait until collection creation finishes
9. Stop the script
* Use CTRL+C if script was started manually
* Wait for script to end automatically if timeout was provided or alternatively use also CTRL+C to stop sooner
10. Check chart files in same directory
`cpu.png, memory.png, disk.png`
11. Example charts and output file provided in "examples" folder of this repository
