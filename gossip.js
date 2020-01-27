var nodeIp;
var timeout;
var $networkStateTable = $("#networkStateTable").find('tbody');

getNodeData = function () {
    $.getJSON(nodeIp + "/networkState", function (networkState) {
        updateNetworkStateTable(networkState)
    });
}

connectToNode = function () {
    nodeIp = $('#nodeIp').val();
    getNodeData(nodeIp);
    timeout = setTimeout(connectToNode, 10000, nodeIp);
};

updateNetworkStateTable = function (networkState) {
    networkState = JSON.parse(networkState);
    let action;
    for (ip in networkState) {
        if (networkStateTable[ip] === undefined) {
            action = addNewTableEntry
        }
        else {
            action = updateExistingEntry
        }
        action(ip, networkState[ip]);
    }
}

updateExistingEntry = function (ip, nodeData) {
    $currentRow = $('#' + ip);
    $currentRow.children()[0].val(ip);
    $currentRow.children()[1].val(revision);
    $currentRow.children()[2].val(nodeData.heartbeat);
    $currentRow.children()[3].val(nodeData.state);
}

addNewTableEntry = function (ip, nodeData) {
    $currentRow = $networkStateTable.append($('<tr>').attr('id', ip));
    $currentRow.append($('<td>').val(ip));
    $currentRow.append($('<td>').val(nodeData.revision));
    $currentRow.append($('<td>').val(nodeData.heartbeat));
    $currentRow.append($('<td>').val(nodeData.state));
}