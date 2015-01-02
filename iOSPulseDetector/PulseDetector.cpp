//
//  PulseDetector.cpp
//  iOSPulseDetector
//
//  Created by Melissa Mozifian on 02/01/2015.
//
//

#include "PulseDetector.hpp"
#include <stdio.h>
#include <cstdio>
#include <algorithm>
#include <iterator>
#include <list>
#include <fstream>
#include <string.h>
#include <stdlib.h>

#include <iostream>
#include <string>
#include <vector>


void PulseDetector::run() {
    
}

void PulseDetector::getForehead(const cv::Rect& face, cv::Rect& forehead) {
    getSubface(face, forehead, 0.50, 0.18, 0.25, 0.15);
    return;
}

void PulseDetector::getSubface(const cv::Rect& face, cv::Rect& sub, float sf_x, float sf_y, float sf_w, float sf_h) {
    assert (face.height != 0 && face.width != 0);
    assert (sf_w > 0.0 && sf_y > 0.0 && sf_w > 0.0 && sf_h > 0.0);
    sub.x = face.x + face.width * sf_x - (face.width * sf_w / 2.0);
    sub.y = face.y + face.height * sf_y - (face.height * sf_h / 2.0);
    sub.width = face.width * sf_w;
    sub.height = face.height * sf_h;
    return;
}

double PulseDetector::calculate_mean(const cv::Mat& image) {
    cv::Scalar means = cv::mean(image);
    return (means.val[0] + means.val[1] + means.val[2]) / 3;
}


double PulseDetector::timestamp() {
    boost::chrono::duration<double> seconds = boost::chrono::system_clock::now() - _start;
    return seconds.count();
}
//
// Return a Hamming window
//http://docs.scipy.org/doc/numpy/reference/generated/numpy.hamming.html
//
vector<double> PulseDetector::hammingWindow(int M) {
    vector<double> window(M);
    if (M == 1) {
        window[0] = 1.0;
    } else {
        for (int n = 0; n < M; ++n) {
            window[n] = 0.54 - 0.46 * cos((2 * M_PI * n) / (M - 1));
        }
    }
    return window;
}

vector<double> PulseDetector::arange(int stop) {
    vector<double> range(stop);
    for (int i=0; i < stop; i++) {
        range[i] = i;
    }
    return range;
}

//
// List operations
//

vector<double> PulseDetector::linspace(double start, double end, int count) {
    vector<double> intervals(count);
    double gap = (end - start) / (count - 1);
    intervals[0] = start;
    for (int i = 1; i < (count - 1); ++i) {
        intervals[i] = intervals[i-1] + gap;
    }
    intervals[count - 1] = end;
    return intervals;
}

double PulseDetector::list_mean(vector<double>& data) {
    assert (!data.empty());
    boost::accumulators::accumulator_set<double, boost::accumulators::stats<boost::accumulators::tag::mean> > acc;
    for_each(data.begin(), data.end(), boost::bind<void>(boost::ref(acc), _1));
    return boost::accumulators::mean(acc);
}

void PulseDetector::list_trimfront(vector<double>& list, int limit) {
    int excess = list.size() - limit;
    if (excess > 0) {
        list.erase(list.begin(), list.begin() + excess);
    }
}

void PulseDetector::list_subtract(vector<double>& data, double value) {
    for (int i = 0; i < data.size(); ++i) {
        data[i] -= value;
    }
}

void PulseDetector::list_multiply(vector<double>& data, double value) {
    for (int i = 0; i < data.size(); ++i) {
        data[i] *= value;
    }
}

void PulseDetector::list_multiply_vector(vector<double>& data, vector<double>& mult) {
    assert (data.size() == mult.size());
    for (int i = 0; i < data.size(); ++i) {
        data[i] *= mult[i];
    }
}

vector<double> PulseDetector::list_filter(vector<double>& data, double low, double high) {
    vector<double> indices;
    for (int i = 0; i < data.size(); ++i) {
        if (data[i] >= low && data[i] <= high) {
            indices.push_back(i);
        }
    }
    return indices;
}

vector<double> PulseDetector::list_pruned(vector<double>& data, vector<double>& indices) {
    vector<double> pruned;
    for (int i = 0; i < indices.size(); ++i) {
        assert (indices[i] >= 0 && indices[i] < data.size());
        pruned.push_back(data[indices[i]]);
    }
    return pruned;
}

int PulseDetector::list_argmax(vector<double>& data) {
    int indmax;
    double argmax = 0;
    for (int i = 0; i < data.size(); ++i) {
        if (data[i] > argmax) {
            argmax = data[i];
            indmax = i;
        }
    }
    return indmax;
}

void PulseDetector::clearBuffers()
{
    _means.clear();
    _times.clear();
    _fftabs.clear();
    _frequencies.clear();
    _pruned.clear();
    _prunedfreq.clear();
    _bpms.clear();
    gap = 0;
}