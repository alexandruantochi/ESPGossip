var nodeIp;
var timeout;
var $networkStateTable = $("#networkStateTable")

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
    let action;
    for (ip in networkState) {
        if ($(ip)[0] === undefined) {
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
    $currentRow.children()[0].text(ip);
    $currentRow.children()[1].text(revision);
    $currentRow.children()[2].text(nodeData.heartbeat);
    $currentRow.children()[3].text(nodeData.state);
}

addNewTableEntry = function (ip, nodeData) {
    $currentRow = $networkStateTable.append($('<tr>').attr('id', ip));
    $currentRow.append($('<td>').text(ip));
    $currentRow.append($('<td>').text(nodeData.revision));
    $currentRow.append($('<td>').text(nodeData.heartbeat));
    $currentRow.append($('<td>').text(nodeData.state));
}