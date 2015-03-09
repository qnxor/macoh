/*
 * FFTW Test part of the MacOH project
 * https://github.com/qnxor/macoh
 *
 * Bogdan Roman, University of Cambridge, 2015
 * http://www.damtp.cam.ac.uk/research/afha/bogdan
 */

#include <stdlib.h>
#include <math.h>
#include "fftw3.h"
#include <omp.h>
#include <time.h>

void* moh_malloc(size_t n)
{
    void* x = fftw_malloc(n);
    if (x)
        return x;
    else
    {
        fprintf(stderr, "Could not allocate memory. Decrease N and retry.\n");
        exit(3);
    }
}

void moh_fill (double* x, int n)
{
    for (int i = 0; i < n*n; ++i)
        x[i] = rand() % n*n;
}

void moh_fill (fftw_complex* x, int n)
{
    for (int i = 0; i < n*n; ++i)
    {
        x[i][0] = rand() % n*n;
        x[i][1] = rand() % n*n;
    }
}

int main(int argc, char **argv)
{
    if (argc < 6 || atoi(argv[1]) < 2)
    {
        printf("Syntax: %s TIME THREADS N TYPE WISDOM\n\
\n\
   TIME - run for continuously for this many seconds\n\
THREADS - number of threads to use, 0 = all cores (x2 if HyperThreaded)\n\
      N - generate a random N-by-N input, N must be > 1\n\
   TYPE - 0=r2r, 1=r2c, 2=c2c\n\
 WISDOM - 0=ESTIMATE, 1=MEASURE, 2=PATIENT, 3=EXHAUSTIVE\n\
\n\
by Bogdan Roman, University of Cambridge, 2015\n\
   http://www.damtp.cam.ac.uk/research/afha/bogdan\n\
Using FFTW3 (http://fftw.org), OpenMP (http://openmp.org)\n\
", argv[0]);
        exit(1);
    }

    double seconds = atof(argv[1]);
    int threads = atoi(argv[2]);
    int n = atoi(argv[3]);
    int type = atoi(argv[4]);
    int wisdom = atoi(argv[5]);
    int omp = threads != 1;
    time_t now, start = time(NULL);
    long count = 0;

    if (threads <= 0)
        threads = omp_get_max_threads();

    fprintf(stderr, "FFTW: size=%d-by-%d, threads=%d, type=%d, wisdom=%d. Planning ...\n",
        seconds, n, n, threads, type, wisdom);

    if (omp)
    {
        fftw_init_threads();
        fftw_plan_with_nthreads(threads);
    }
    
    switch (wisdom)
    {
        case 0: wisdom = FFTW_ESTIMATE; break;
        case 1: wisdom = FFTW_MEASURE; break;
        case 2: wisdom = FFTW_PATIENT; break;
        case 3: wisdom = FFTW_EXHAUSTIVE; break;
        default: printf("Unknown wisdom: %d\n", wisdom); exit(2);
    }
    
    //if (argc > 2)
    //    fftw_import_wisdom_from_filename(argv[3]);

    fftw_plan p;
    void *x, *y;

    switch(type)
    {
        case 0:
            x = moh_malloc(n*n * sizeof(double));
            y = moh_malloc(n*n * sizeof(double));
            moh_fill((double*)x, n);
            p = fftw_plan_r2r_2d(n, n, (double*)x, (double*)y, FFTW_REDFT10, FFTW_REDFT10, wisdom);
            break;
        case 1:
            x = moh_malloc(n*n * sizeof(double));
            y = moh_malloc(n*n * sizeof(fftw_complex));
            moh_fill((double*)x, n);
            p = fftw_plan_dft_r2c_2d(n, n, (double*)x, (fftw_complex*)y, wisdom);
            break;
        case 2:
            x = moh_malloc(n*n * sizeof(fftw_complex));
            y = moh_malloc(n*n * sizeof(fftw_complex));
            moh_fill((fftw_complex*)x, n);
            p = fftw_plan_dft_2d(n, n, (fftw_complex*)x, (fftw_complex*)y, FFTW_FORWARD, wisdom);
            break;
        default:
            printf("Unknown type: %d\n", wisdom); exit(2);
    }

    fprintf(stderr, "FFTW: done planning in %.2f seconds. Looping for %.1f seconds ...\n", 
        difftime(time(NULL),start), seconds);

    for (count = 0, start = time(NULL); difftime(time(NULL), start) < seconds; ++count)
        fftw_execute(p);

    printf("Done: %.2f ffts/sec\n", (double)count/difftime(time(NULL),start));

    //if (argc > 2)
    //    fftw_export_wisdom_to_filename("fftw.wis");
    
    fftw_destroy_plan(p);
    if (omp)
        fftw_cleanup_threads();
    fftw_free(x);
    fftw_free(y);
}
