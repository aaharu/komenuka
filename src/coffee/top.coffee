"use strict"
$(() ->
    $.ajax(
        type: "GET"
        url: "/api/images/recent"
        dataType: "json"
    ).done((data, textStatus, jqXHR) ->
        template = T.recent_images.render({images: data})
        $("#list").append(template)
    ).fail((jqXHR, textStatus, errorThrown) -> console.log(errorThrown))
)
