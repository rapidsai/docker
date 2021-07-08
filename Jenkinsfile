// you can add more axes and this will still work
// Map matrix_axes = [
//     CUDA_VER: ['11.0', '11.2'],
//     LINUX_VER: ['ubuntu18.04', 'ubuntu20.04', 'centos7', 'centos8'],
//     PYTHON_VER: ['3.7', '3.8'],
//     IMAGE_TYPE: ['base', 'runtime'],
// ]
Map matrix_axes = [
    CUDA_VER: ['11.0', '11.2'],
    LINUX_VER: ['ubuntu18.04'],
    PYTHON_VER: ['3.7'],
    IMAGE_TYPE: ['base'],
    RAPIDS_VER: ['21.08'],
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

List axes = getMatrixAxes(matrix_axes)

// parallel task map
Map tasks = [failFast: false]

for(int i = 0; i < axes.size(); i++) {
    // convert the Axis into valid values for withEnv step
    Map axis = axes[i]
    List axisEnv = axis.collect { k, v ->
        "${k}=${v}"
    }


    String nodeLabel = "CUDA_VER:${axis['CUDA_VER']} && LINUX_VER:${axis['LINUX_VER']} && PYTHON_VER:${axis['PYTHON_VER']} && IMAGE_TYPE:${axis['IMAGE_TYPE']}"
    tasks[axisEnv.join(', ')] = { ->
        node {
            checkout scm
            withEnv(axisEnv) {
                stage("CORE Build ${IMAGE_TYPE} - ${CUDA_VER} - ${LINUX_VER} - ${PYTHON_VER}") {
                    echo nodeLabel
                    sh 'bash ci/build.sh core'
                }
                stage("CORE Test ${IMAGE_TYPE} - ${CUDA_VER} - ${LINUX_VER} - ${PYTHON_VER}") {
                    echo nodeLabel
                    sh 'echo Do Test for ${IMAGE_TYPE} - ${CUDA_VER} - ${LINUX_VER} - ${PYTHON_VER}'
                }
                stage("STD Build ${IMAGE_TYPE} - ${CUDA_VER} - ${LINUX_VER} - ${PYTHON_VER}") {
                    echo nodeLabel
                    sh 'bash ci/build.sh std'
                }
                stage("CLX Build ${IMAGE_TYPE} - ${CUDA_VER} - ${LINUX_VER} - ${PYTHON_VER}") {
                    echo nodeLabel
                    sh 'bash ci/build.sh clx'
                }
            }
        }
    }
}

stage("Matrix builds") {
    parallel(tasks)
}
