// you can add more axes and this will still work
Map matrix_axes = [
    PLATFORM: ['linux', 'windows', 'mac'],
    BROWSER: ['firefox', 'chrome', 'safari', 'edge']
]

@NonCPS
List getMatrixAxes(Map matrix_axes) {
    List axes = []
    matrix_axes.each { axis, values ->
        List axisList = []
        values.each { value ->
            axisList << [(axis): value]
        }
        axes << axisList
    }
    // calculate cartesian product
    axes.combinations()*.sum()
}

// filter the matrix axes since
// Safari is not available on Linux and
// Edge is only available on Windows
List axes = getMatrixAxes(matrix_axes).findAll { axis ->
    !(axis['BROWSER'] == 'safari' && axis['PLATFORM'] == 'linux') &&
    !(axis['BROWSER'] == 'edge' && axis['PLATFORM'] != 'windows')
}

// parallel task map
Map tasks = [failFast: false]

for(int i = 0; i < axes.size(); i++) {
    // convert the Axis into valid values for withEnv step
    Map axis = axes[i]
    List axisEnv = axis.collect { k, v ->
        "${k}=${v}"
    }
    // let's say you have diverse agents among Windows, Mac and Linux all of
    // which have proper labels for their platform and what browsers are
    // available on those agents.
    String nodeLabel = "os:${axis['PLATFORM']} && browser:${axis['BROWSER']}"
    tasks[axisEnv.join(', ')] = { ->
        node {
            withEnv(axisEnv) {
                stage("Build ${PLATFORM} - ${BROWSER}") {
                    echo nodeLabel
                    sh 'echo Do Build for ${PLATFORM} - ${BROWSER}'
                }
                stage("Test ${PLATFORM} - ${BROWSER}") {
                    echo nodeLabel
                    sh 'echo Do Test for ${PLATFORM} - ${BROWSER}'
                }
            }
        }
    }
}

stage("Matrix builds") {
    parallel(tasks)
}
