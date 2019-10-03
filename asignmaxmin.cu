#include<iostream>
#include<stdlib.h>
#include<cuda.h>
#include<time.h>

#define BLOCK_SIZE 64
#define SOA 512

void random_ints(int *data,int size)
{
	int i;
	for(i=0;i<size;i++)
	{
		data[i]=rand()%size;
	}
}

__global__ void ReductionMax2(int *input,int *results,int n)
{
	__shared__ int sdata[BLOCK_SIZE];
	unsigned int i=blockIdx.x*blockDim.x+threadIdx.x;
	unsigned int tx=threadIdx.x;
	int x=-INT_MAX;
	if(i<n)
		x=input[i];
	sdata[tx]=x;
	__syncthreads();
	for(unsigned int offset=blockDim.x>>1;offset>0;offset >>=1)
	{
		__syncthreads();
		if(tx<offset)
		{
			if(sdata[tx+offset]>sdata[tx])
				sdata[tx]=sdata[tx+offset];
		}
	}
	if(threadIdx.x==0)
	{
		results[blockIdx.x]=sdata[0];
	}
}
int  main()
{
	int num_blocks=SOA/BLOCK_SIZE;
	int num_threads=BLOCK_SIZE,i;
	unsigned int mem_size_a=sizeof(int)*SOA;
	int *h_a=(int*)malloc(mem_size_a);
	random_ints(h_a,SOA);
	int *d_a;
	cudaMalloc((void**)&d_a,mem_size_a);
	cudaMemcpy(d_a,h_a,mem_size_a,cudaMemcpyHostToDevice);
	unsigned int mem_size_b=sizeof(int)*num_blocks;
	int *d_b;
	cudaMalloc((void**)&d_b,mem_size_b);
	int *h_b=(int*)malloc(mem_size_b);
	unsigned int mem_size_c=sizeof(int);
	int *d_c;
	cudaMalloc((void**)&d_c,mem_size_c);

	ReductionMax2<<<num_blocks,num_threads>>>(d_a,d_b,SOA);
	cudaMemcpy(h_b,d_b,mem_size_b,cudaMemcpyDeviceToHost);
	ReductionMax2<<<1,num_blocks>>>(d_b,d_c,num_blocks);

	int *h_c=(int*)malloc(mem_size_c);
	cudaMemcpy(h_c,d_c,mem_size_c,cudaMemcpyDeviceToHost);

	int j;
			for(j=0;j<SOA;j++)
			{
				std::cout<<h_a[j]<<",";
			}
			std::cout<<"\nblock max";
			for(j=0;j<num_blocks;j++)
			{
				std::cout<<h_b[j]<<",";
			}
			std::cout<<"\nparallel max="<<*h_c;
}
