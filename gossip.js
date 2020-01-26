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
    $currentRow.children()[0] = ip;
    $currentRow.children()[1] = nodeData.revision;
    $currentRow.children()[2] = nodeData.heartbeat;
    $currentRow.children()[3] = nodeData.state;
}

addNewTableEntry = function (ip, nodeData) {
    $currentRow = $networkStateTable.append($('<tr>').attr('id', ip));
    $currentRow.append($('<td>').value(ip));
    $currentRow.append($('<td>').value(nodeData.revision));
    $currentRow.append($('<td>').value(nodeData.heartbeat));
    $currentRow.append($('<td>').value(nodeData.state));
}