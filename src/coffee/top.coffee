"use strict"
$(() ->
    $.ajax(
        type: "GET"
        url: "/api/images/recent"
        dataType: "json"
    ).done((data, textStatus, jqXHR) ->
        json = JSON.parse(data)
        template = T.recent_images.render(json)
        $("#list").append(template)
    ).fail((jqXHR, textStatus, errorThrown) -> console.log(errorThrown))
)
