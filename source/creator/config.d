/**
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen


    Here you will find easy access for some configurable things you can set for Inochi Creator builds
    These are mostly useful for unofficial builds. Make sure to update this file for unofficial builds
    as otherwise we'll end up getting support requests for distributions we don't maintain.

    -- NOTE --
    SHOULD indicates that a line should be changed if the condition given is met.
*/
module creator.config;

/**
    Name of the artist for the included banner.

    If you change the banner you SHOULD change this.
*/
enum INC_BANNER_ARTIST_NAME = "七乃ななせ";

/**
    Link to the artist's preferred social media,
    or art posting page.
*/
enum INC_BANNER_ARTIST_PAGE = "https://twitter.com/nana_nono120";

/**
    URI for bug reports, for unofficial builds this SHOULD be changed.
*/
enum INC_BUG_REPORT_URI = "https://github.com/Inochi2D/inochi-creator/issues/new?assignees=&labels=bug&template=bug-report.yml&title=%5BBUG%5D";

/**
    URI for feature requests, for the most part this doesn't need to be changed
    unless you're making a fork.
*/
enum INC_FEATURE_REQ_URI = "https://github.com/Inochi2D/inochi-creator/issues/new?assignees=&labels=enhancement&template=feature_request.yml&title=%5BFeature+Request%5D";