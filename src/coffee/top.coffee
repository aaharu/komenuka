"use strict"
$(() ->
    $.ajax("/api/images/recent", {
        type: "GET"
        dataType: "json"
    }).done((data, textStatus, jqXHR) ->
        template = T.recent_images.render(data)
        $("#list").append(template)
        return
    ).fail((jqXHR, textStatus, errorThrown) ->
        console.log(errorThrown)
        return
    )
    return
)
