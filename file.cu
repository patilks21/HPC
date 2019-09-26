#include<iostream>
#include<stdlib.h>
__global__ void add(int *a,int *b,int *c)
{
	int index=blockIdx.x*blockDim.x+threadIdx.x;
	c[index]=a[index]+b[index];
}
void random_ints(int *a,int N)
{
	int i;
	for(i=0;i<N;i++)
	{
		a[i]=i;
	}
}
#define N 2048
#define THREADS_PER_BLOCK 64

int main(void)
{
	int *a,*b,*c;
	int *d_a,*d_b,*d_c;
	int size=N*sizeof(int);

	cudaMalloc((void **)&d_a,size);
	cudaMalloc((void **)&d_b,size);
	cudaMalloc((void **)&d_c,size);

	a=(int *)malloc(size);random_ints(a,N);
	b=(int *)malloc(size);random_ints(b,N);
	c=(int *)malloc(size);

	cudaMemcpy(d_a,a,size,cudaMemcpyHostToDevice);
	cudaMemcpy(d_b,b,size,cudaMemcpyHostToDevice);

	add<<<N/THREADS_PER_BLOCK,THREADS_PER_BLOCK>>>(d_a,d_b,d_c);

	cudaMemcpy(c,d_c,size,cudaMemcpyDeviceToHost);

	cudaFree(d_a);
	cudaFree(d_b);
	cudaFree(d_c);

	int i;
		for(i=0;i<N;i++)
		{
			std::cout<<c[i]<<"\n";
		}

	return 0;
}
