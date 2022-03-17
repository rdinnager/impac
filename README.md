
<!-- README.md is generated from README.Rmd. Please edit that file -->

# impac

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/rdinnager/impac/workflows/R-CMD-check/badge.svg)](https://github.com/rdinnager/impac/actions)
<!-- badges: end -->

The goal of `{impac}` is to create packed image mosaics. The main
function `impac`, takes a set of images, or a function that generates
images and packs them into a larger image as tightly as possible,
scaling as necessary, using a greedy algorithm (so don’t expect it to be
fast\!). It is inspired by [this python
script](https://github.com/qnzhou/Mosaic%5D). The main upgrade in this
package is the ability to feed the algorithm a generator function, which
generates an images, as opposed to just a list of pre-existing images
(though it can do this too).

## Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("rdinnager/impac")
```

## Example

This document and hence the images below are regenerated once a day
automatically. No two will ever be alike.

First we load the packages we need for these examples:

``` r
library(impac)
library(Rvcg)
library(rgl)
library(rphylopic)
```

Next we create an R function to generate an image. In this case, we use
the package `rgl` to plot a simple 3d shape, chosen randomly from a set
of possibilities:

``` r

generate_platonic <- function(i, swidth = 200, sheight = 200, cols = rainbow(100)) {
  
  shape <- sample(c("sphere",
                    "spherical_cap",
                    "tetrahedron",
                    "dodecahedron",
                    "octahedron",
                    "icosahedron",
                    "hexahedron",
                    "cube",
                    "cone"),
                  1)
  
  mesh <- switch (shape,
    sphere = Rvcg::vcgSphere(),
    spherical_cap = Rvcg::vcgSphericalCap(),
    tetrahedron = Rvcg::vcgTetrahedron(),
    dodecahedron = Rvcg::vcgDodecahedron(),
    octahedron = Rvcg::vcgOctahedron(),
    icosahedron = Rvcg::vcgIcosahedron(),
    hexahedron = Rvcg::vcgHexahedron(),
    cube = Rvcg::vcgBox(),
    cone = Rvcg::vcgCone(2, 0, 6)
  )
  
  scales <- c(1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 3, 4)
  mesh <- rgl::scale3d(mesh, 
                       sample(scales, 1),
                       sample(scales, 1),
                       sample(scales, 1))
  
  mesh <- rgl::rotate3d(mesh, runif(1, 0, 2 * pi), 0, 0, 1)
  mesh <- rgl::rotate3d(mesh, runif(1, 0, 2 * pi), 0, 1, 0)
  mesh <- rgl::rotate3d(mesh, runif(1, 0, 2 * pi), 1, 0, 0)
  
  rgl::shade3d(mesh, col = sample(cols, 1),
               specular = "grey")
  
  png_file <- tempfile(fileext = ".png")
  rgl::snapshot3d(filename = png_file, width = swidth, height = sheight,
                  webshot = FALSE)
  rgl::close3d()
  
  im2 <- imager::load.image(png_file)
  im <- imager::imfill(swidth, sheight, val = c(0, 0, 0, 1))
  im[ , , , 1:3] <- im2 
  im[imager::R(im) == 1 & imager::G(im) == 1 & imager::B(im) == 1] <- 0
  
  im  
 
}
```

Now we feed our function to the `impac()` function, which packs the
generated images onto a canvas:

``` r
shapes <- impac(generate_platonic, progress = FALSE, show_every = 0, bg = "white")
imager::save.image(shapes$image, "man/figures/R_gems.png")
```

![Pretty R gems - Packed images of 3d shapes drawn with
{rgl}](man/figures/R_gems.png)

Now let’s pack some Phylopic images\! These are silhouettes of organisms
from the [Phylopic](http://phylopic.org/) project. We will use the
`rphylopic` package to grab a random Phylopic image for packing:

``` r
all_images <- rphylopic::image_list(1, 10000)
all_images <- unlist(all_images)
get_phylopic <- function(i, max_size = 400, isize = 1024) {
  fail <- TRUE
  while(fail) {
    uuid <- sample(all_images, 1)
    pp <- try(rphylopic::image_data(uuid, isize), silent = TRUE)
    if(!inherits(pp, "try-error")) {
      fail <- FALSE
    }
  }
  rot <- aperm(pp$uid, c(2, 1, 3))
  dims <- dim(rot)
  im <- imager::as.cimg(as.vector(rot), dim = c(dims[1], dims[2], 1, dims[3]))
  max_dim <- which.max(dims[1:2])
  other_dim <- (max_size / dims[max_dim]) * dims[1:2][-max_dim]
  new_size <- c(0, 0)
  new_size[max_dim] <- max_size
  new_size[-max_dim] <- other_dim
  im <- imager::resize(im, new_size[1], new_size[2], interpolation_type = 6)
  im <- imager::imchange(im, ~ . < 0, ~ 0)
  im <- imager::imchange(im, ~ . > 1, ~ 1)
  ## this adds custom metadata
  list(im, uuid = uuid)
}
```

Now we run `impac` on our phylopic generating function:

``` r
phylopics <- impac(get_phylopic, progress = FALSE, show_every = 0, bg = "white", min_scale = 0.01)
imager::save.image(phylopics$image, "man/figures/phylopic_a_pack.png")
```

![Packed images of organism silhouettes from
Phylopic](man/figures/phylopic_a_pack.png)

Now we extract the artists who made the above images using the uid of
image.

``` r
image_dat <- lapply(phylopics$meta$uuid, 
                    function(x) {Sys.sleep(2); rphylopic::image_get(x, options = c("credit"))$credit})
```

## Artists whose work is showcased:

\<U+4E8E\>\<U+5DDD\>\<U+4E91\>, Smokeybjb, Tom Tarrant (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Andrew R.
Gehrke, A. H. Baldwin (vectorized by T. Michael Keesey), Tracy A. Heath,
Yan Wong from illustration by Charles Orbigny, Chloé Schmidt, Matt
Crook, Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow
(vectorized by T. Michael Keesey), Beth Reinke, Zimices, Andy Wilson,
Margot Michaud, Xavier Giroux-Bougard, Jagged Fang Designs, Gareth
Monger, James R. Spotila and Ray Chatterji, T. Michael Keesey, Ferran
Sayol, Sam Droege (photography) and T. Michael Keesey (vectorization),
Gabriela Palomo-Munoz, Andreas Hejnol, Dmitry Bogdanov (vectorized by T.
Michael Keesey), Amanda Katzer, Milton Tan, Kamil S. Jaron, Scott
Hartman, Todd Marshall, vectorized by Zimices, Felix Vaux, Jiekun He,
Andrew A. Farke, shell lines added by Yan Wong, Sarah Werning, Tasman
Dixon, Nobu Tamura (vectorized by T. Michael Keesey), Nobu Tamura,
vectorized by Zimices, Scarlet23 (vectorized by T. Michael Keesey),
Mathew Wedel, Steven Coombs, Lip Kee Yap (vectorized by T. Michael
Keesey), Charles R. Knight, vectorized by Zimices, Martin R. Smith,
after Skovsted et al 2015, SauropodomorphMonarch, Chris huh, FunkMonk,
Karla Martinez, Markus A. Grohme, Siobhon Egan, Emily Willoughby,
Fernando Carezzano, NOAA Great Lakes Environmental Research Laboratory
(illustration) and Timothy J. Bartley (silhouette), Madeleine Price
Ball, Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey), Steven
Traver, Falconaumanni and T. Michael Keesey, Remes K, Ortega F, Fierro
I, Joger U, Kosma R, et al.,
\<U+0414\>\<U+0438\>\<U+0411\>\<U+0433\>\<U+0434\> (vectorized by T.
Michael Keesey), T. Michael Keesey (photo by Darren Swim), Michael Day,
Javier Luque, Mali’o Kodis, photograph by John Slapcinsky, Joanna Wolfe,
Noah Schlottman, photo from Moorea Biocode, L. Shyamal, Michelle Site,
Roberto Díaz Sibaja, Jimmy Bernot, Christine Axon, Andrew A. Farke,
Chris A. Hamilton, Mali’o Kodis, photograph by “Wildcat Dunny”
(<http://www.flickr.com/people/wildcat_dunny/>), Erika Schumacher, Jaime
Headden, Matt Martyniuk, Terpsichores, Gustav Mützel, Abraão Leite, Ingo
Braasch, Campbell Fleming, Daniel Jaron, Melissa Broussard, Armin
Reindl, Adam Stuart Smith (vectorized by T. Michael Keesey), Henry
Fairfield Osborn, vectorized by Zimices, Mali’o Kodis, image from the
Smithsonian Institution, MPF (vectorized by T. Michael Keesey), C.
Abraczinskas, Michael Scroggie, Lisa M. “Pixxl” (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Cagri Cevrim,
Yan Wong from photo by Denes Emoke, Maija Karala, S.Martini, Harold N
Eyster, C. Camilo Julián-Caballero, Blanco et al., 2014, vectorized by
Zimices, Notafly (vectorized by T. Michael Keesey), Jaime Headden
(vectorized by T. Michael Keesey), RS, Natasha Vitek, Kanchi Nanjo, Yan
Wong, Tony Ayling, David Orr, Lauren Anderson, Griensteidl and T.
Michael Keesey, Noah Schlottman, Dexter R. Mardis, Smokeybjb, vectorized
by Zimices, Scott Hartman, modified by T. Michael Keesey, T. Michael
Keesey (after Walker & al.), Henry Lydecker, Tauana J. Cunha, Ignacio
Contreras, Lankester Edwin Ray (vectorized by T. Michael Keesey), Pete
Buchholz, Eduard Solà (vectorized by T. Michael Keesey), Carlos
Cano-Barbacil, Gopal Murali, Dean Schnabel, Juan Carlos Jerí, Kimberly
Haddrell, Richard Ruggiero, vectorized by Zimices, Iain Reid, Mateus
Zica (modified by T. Michael Keesey), Mark Hannaford (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, CNZdenek, Conty
(vectorized by T. Michael Keesey), Rainer Schoch, Yan Wong from drawing
by Joseph Smit, Sergio A. Muñoz-Gómez, Birgit Lang, Ricardo Araújo,
xgirouxb, Skye M, T. Michael Keesey (after Marek Velechovský), T.
Michael Keesey (after Kukalová), Robert Bruce Horsfall, vectorized by
Zimices, Rebecca Groom, Heinrich Harder (vectorized by William Gearty),
Dmitry Bogdanov, Steven Haddock • Jellywatch.org, T. Michael Keesey
(after James & al.), Mattia Menchetti / Yan Wong, Jose Carlos
Arenas-Monroy, Joris van der Ham (vectorized by T. Michael Keesey), Jack
Mayer Wood, Kai R. Caspar, Brad McFeeters (vectorized by T. Michael
Keesey), Felix Vaux and Steven A. Trewick, Philip Chalmers (vectorized
by T. Michael Keesey), Gordon E. Robertson, CDC (Alissa Eckert; Dan
Higgins), Michael P. Taylor, Mali’o Kodis, photograph by Hans
Hillewaert, Oscar Sanisidro, U.S. National Park Service (vectorized by
William Gearty), Martin R. Smith, Catherine Yasuda, Duane Raver
(vectorized by T. Michael Keesey), T. Michael Keesey (from a mount by
Allis Markham), Haplochromis (vectorized by T. Michael Keesey), B. Duygu
Özpolat, Didier Descouens (vectorized by T. Michael Keesey), Tyler
McCraney, Maxwell Lefroy (vectorized by T. Michael Keesey), Matt
Dempsey, John Conway, Tyler Greenfield, Collin Gross, Dianne Bray /
Museum Victoria (vectorized by T. Michael Keesey), Daniel Stadtmauer,
Julie Blommaert based on photo by Sofdrakou, Nobu Tamura, Cesar Julian,
Jake Warner, Robert Hering, T. Tischler, Robert Gay, modified from
FunkMonk (Michael B.H.) and T. Michael Keesey., Martin Kevil, Katie S.
Collins, Lukasiniho, Obsidian Soul (vectorized by T. Michael Keesey),
Arthur S. Brum, Agnello Picorelli, Manabu Bessho-Uehara, Shyamal, Diego
Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli,
Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by
T. Michael Keesey), Julio Garza, Aviceda (photo) & T. Michael Keesey,
Alex Slavenko

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    919.256614 |    723.372445 | \<U+4E8E\>\<U+5DDD\>\<U+4E91\>                                                                                                                                        |
|   2 |    298.628820 |     75.326614 | Smokeybjb                                                                                                                                                             |
|   3 |    773.829836 |    105.609316 | Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
|   4 |    658.969304 |    439.252796 | Andrew R. Gehrke                                                                                                                                                      |
|   5 |    234.410266 |    180.233287 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                                       |
|   6 |     67.627846 |    267.323792 | Tracy A. Heath                                                                                                                                                        |
|   7 |    342.989005 |    671.345174 | Yan Wong from illustration by Charles Orbigny                                                                                                                         |
|   8 |    505.915735 |    333.775069 | Chloé Schmidt                                                                                                                                                         |
|   9 |    240.164287 |    387.756088 | Matt Crook                                                                                                                                                            |
|  10 |    615.605218 |    127.304036 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
|  11 |    552.572048 |    258.362209 | Beth Reinke                                                                                                                                                           |
|  12 |    503.790403 |    442.696546 | Zimices                                                                                                                                                               |
|  13 |    470.937255 |     96.290009 | Andy Wilson                                                                                                                                                           |
|  14 |    142.875918 |    286.260988 | Margot Michaud                                                                                                                                                        |
|  15 |    623.301779 |    590.769129 | Xavier Giroux-Bougard                                                                                                                                                 |
|  16 |    681.896138 |    719.499495 | Andy Wilson                                                                                                                                                           |
|  17 |    852.239538 |    258.714600 | Jagged Fang Designs                                                                                                                                                   |
|  18 |    163.216940 |    668.075917 | Andy Wilson                                                                                                                                                           |
|  19 |    226.932397 |    673.605594 | Gareth Monger                                                                                                                                                         |
|  20 |    912.933672 |    550.901740 | James R. Spotila and Ray Chatterji                                                                                                                                    |
|  21 |    914.451678 |    182.791417 | T. Michael Keesey                                                                                                                                                     |
|  22 |     89.074050 |    527.319656 | Ferran Sayol                                                                                                                                                          |
|  23 |    524.985930 |    725.284111 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                        |
|  24 |    836.074568 |    382.425557 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  25 |     63.375428 |    651.186028 | Andreas Hejnol                                                                                                                                                        |
|  26 |    896.291858 |     79.847436 | Chloé Schmidt                                                                                                                                                         |
|  27 |    107.833337 |     99.837232 | Andy Wilson                                                                                                                                                           |
|  28 |    396.109961 |    511.531109 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  29 |    358.387080 |    398.918825 | Amanda Katzer                                                                                                                                                         |
|  30 |    452.340176 |    221.672397 | Andy Wilson                                                                                                                                                           |
|  31 |    700.319414 |     71.742446 | Milton Tan                                                                                                                                                            |
|  32 |    827.855701 |    520.188011 | Jagged Fang Designs                                                                                                                                                   |
|  33 |    662.276994 |    331.362144 | Kamil S. Jaron                                                                                                                                                        |
|  34 |    293.077950 |    522.352720 | Andy Wilson                                                                                                                                                           |
|  35 |    357.403802 |    110.053422 | Zimices                                                                                                                                                               |
|  36 |    928.031641 |    301.816075 | Scott Hartman                                                                                                                                                         |
|  37 |    940.693481 |    479.848601 | Zimices                                                                                                                                                               |
|  38 |    698.336875 |    245.261340 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
|  39 |    365.481280 |    745.294521 | Ferran Sayol                                                                                                                                                          |
|  40 |    213.781598 |    321.705181 | Felix Vaux                                                                                                                                                            |
|  41 |    379.948830 |    302.157554 | Jiekun He                                                                                                                                                             |
|  42 |    272.214507 |    254.128401 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                        |
|  43 |    523.537555 |     79.736552 | Sarah Werning                                                                                                                                                         |
|  44 |    325.680104 |    607.859173 | Tasman Dixon                                                                                                                                                          |
|  45 |    589.898645 |    517.147067 | Scott Hartman                                                                                                                                                         |
|  46 |    132.654635 |    747.295038 | Margot Michaud                                                                                                                                                        |
|  47 |    400.782533 |     42.259688 | Scott Hartman                                                                                                                                                         |
|  48 |    183.344207 |     20.015417 | NA                                                                                                                                                                    |
|  49 |     76.511723 |    373.808258 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  50 |    807.438340 |    196.544024 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
|  51 |    208.974024 |    117.221107 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                           |
|  52 |    934.962400 |    362.348895 | Mathew Wedel                                                                                                                                                          |
|  53 |    320.253683 |    447.382028 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  54 |    211.541372 |    557.670545 | Steven Coombs                                                                                                                                                         |
|  55 |     68.809717 |    421.728631 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  56 |     70.602129 |    180.788563 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                         |
|  57 |    724.953524 |    417.662466 | NA                                                                                                                                                                    |
|  58 |    949.764172 |    636.339581 | Charles R. Knight, vectorized by Zimices                                                                                                                              |
|  59 |     29.379936 |     85.452784 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
|  60 |    787.235249 |    780.368502 | Scott Hartman                                                                                                                                                         |
|  61 |    456.683747 |    643.564739 | Margot Michaud                                                                                                                                                        |
|  62 |    339.364116 |     28.540863 | Scott Hartman                                                                                                                                                         |
|  63 |    987.436483 |    580.078473 | T. Michael Keesey                                                                                                                                                     |
|  64 |    494.418916 |    776.671628 | Ferran Sayol                                                                                                                                                          |
|  65 |    187.580813 |    597.990151 | Scott Hartman                                                                                                                                                         |
|  66 |    636.904906 |    777.757101 | SauropodomorphMonarch                                                                                                                                                 |
|  67 |    606.815921 |     38.849740 | Felix Vaux                                                                                                                                                            |
|  68 |    397.842016 |    193.494770 | Chris huh                                                                                                                                                             |
|  69 |    630.037755 |    683.247186 | FunkMonk                                                                                                                                                              |
|  70 |    798.279193 |     23.549226 | Jagged Fang Designs                                                                                                                                                   |
|  71 |    608.010281 |    400.910077 | Karla Martinez                                                                                                                                                        |
|  72 |    460.989525 |     17.853307 | Markus A. Grohme                                                                                                                                                      |
|  73 |    210.803162 |    180.716951 | Siobhon Egan                                                                                                                                                          |
|  74 |    477.045641 |    486.027485 | Emily Willoughby                                                                                                                                                      |
|  75 |    429.686487 |    254.574646 | Jagged Fang Designs                                                                                                                                                   |
|  76 |    466.035958 |    391.798787 | Scott Hartman                                                                                                                                                         |
|  77 |    303.126624 |    417.595477 | Fernando Carezzano                                                                                                                                                    |
|  78 |    562.674970 |    646.169776 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
|  79 |    238.449535 |    451.051804 | Madeleine Price Ball                                                                                                                                                  |
|  80 |    965.406044 |    440.277954 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  81 |    969.520109 |    250.643314 | Zimices                                                                                                                                                               |
|  82 |    625.354754 |     10.761203 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                            |
|  83 |    731.826411 |    490.013211 | Gareth Monger                                                                                                                                                         |
|  84 |    169.682963 |    532.545264 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  85 |    613.785968 |    258.168191 | Steven Traver                                                                                                                                                         |
|  86 |    543.400061 |    165.835174 | Gareth Monger                                                                                                                                                         |
|  87 |    860.892434 |    224.797156 | Zimices                                                                                                                                                               |
|  88 |    863.661043 |    606.545597 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
|  89 |    726.047298 |    187.192711 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                                 |
|  90 |    487.198413 |    550.984683 | NA                                                                                                                                                                    |
|  91 |    148.065438 |    389.824883 | \<U+0414\>\<U+0438\>\<U+0411\>\<U+0433\>\<U+0434\> (vectorized by T. Michael Keesey)                                                                                  |
|  92 |    352.537823 |    249.457018 | T. Michael Keesey (photo by Darren Swim)                                                                                                                              |
|  93 |    600.005529 |    478.199106 | Chris huh                                                                                                                                                             |
|  94 |    322.274199 |    570.253899 | Zimices                                                                                                                                                               |
|  95 |    635.732479 |    537.687816 | Jagged Fang Designs                                                                                                                                                   |
|  96 |    260.978265 |    740.666909 | Michael Day                                                                                                                                                           |
|  97 |    531.841965 |    782.951848 | Jagged Fang Designs                                                                                                                                                   |
|  98 |    823.423592 |    710.377155 | Jagged Fang Designs                                                                                                                                                   |
|  99 |    417.315290 |    432.321398 | Javier Luque                                                                                                                                                          |
| 100 |    818.052190 |    155.171902 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                           |
| 101 |    789.281561 |    663.999584 | Joanna Wolfe                                                                                                                                                          |
| 102 |    831.505490 |    607.659555 | NA                                                                                                                                                                    |
| 103 |    962.860465 |    104.452203 | Noah Schlottman, photo from Moorea Biocode                                                                                                                            |
| 104 |     39.290388 |    483.146633 | L. Shyamal                                                                                                                                                            |
| 105 |    582.955315 |    218.523946 | Michelle Site                                                                                                                                                         |
| 106 |    971.444956 |    384.442874 | Jagged Fang Designs                                                                                                                                                   |
| 107 |     84.366174 |    344.708695 | Tasman Dixon                                                                                                                                                          |
| 108 |    852.499838 |    294.956874 | Zimices                                                                                                                                                               |
| 109 |    831.144046 |    768.913479 | Roberto Díaz Sibaja                                                                                                                                                   |
| 110 |    686.959533 |    701.387210 | Jimmy Bernot                                                                                                                                                          |
| 111 |     71.631354 |     46.488590 | NA                                                                                                                                                                    |
| 112 |    991.945737 |    414.313808 | Andy Wilson                                                                                                                                                           |
| 113 |    287.423948 |    703.456320 | Christine Axon                                                                                                                                                        |
| 114 |    699.242702 |    674.469343 | Andrew A. Farke                                                                                                                                                       |
| 115 |    918.658261 |    256.867568 | Steven Traver                                                                                                                                                         |
| 116 |    407.757444 |    579.781727 | Gareth Monger                                                                                                                                                         |
| 117 |     15.299037 |    389.789965 | Zimices                                                                                                                                                               |
| 118 |    979.428684 |     38.976172 | Chris A. Hamilton                                                                                                                                                     |
| 119 |    365.671108 |    558.552442 | Kamil S. Jaron                                                                                                                                                        |
| 120 |    988.065007 |    199.388091 | Ferran Sayol                                                                                                                                                          |
| 121 |    190.559132 |    513.104585 | Mali’o Kodis, photograph by “Wildcat Dunny” (<http://www.flickr.com/people/wildcat_dunny/>)                                                                           |
| 122 |    157.639139 |    438.721786 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 123 |    399.710512 |    555.088122 | Gareth Monger                                                                                                                                                         |
| 124 |    767.103911 |    337.179495 | Erika Schumacher                                                                                                                                                      |
| 125 |     23.729565 |    639.107536 | Jagged Fang Designs                                                                                                                                                   |
| 126 |    363.068596 |    164.382978 | Jaime Headden                                                                                                                                                         |
| 127 |    436.467745 |    706.030461 | Matt Martyniuk                                                                                                                                                        |
| 128 |    696.106068 |    301.223676 | \<U+4E8E\>\<U+5DDD\>\<U+4E91\>                                                                                                                                        |
| 129 |    276.734874 |     40.584864 | Jagged Fang Designs                                                                                                                                                   |
| 130 |    149.862597 |    564.890943 | Jagged Fang Designs                                                                                                                                                   |
| 131 |    127.490292 |    433.440066 | NA                                                                                                                                                                    |
| 132 |    839.919560 |    747.879380 | NA                                                                                                                                                                    |
| 133 |    963.633078 |    343.306471 | Zimices                                                                                                                                                               |
| 134 |     40.111291 |    521.214767 | Terpsichores                                                                                                                                                          |
| 135 |    159.682308 |    408.593678 | Gustav Mützel                                                                                                                                                         |
| 136 |    439.679363 |    278.498677 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 137 |    882.514297 |    186.360457 | Abraão Leite                                                                                                                                                          |
| 138 |    902.753974 |    232.995931 | Ingo Braasch                                                                                                                                                          |
| 139 |    651.824273 |    269.007075 | Campbell Fleming                                                                                                                                                      |
| 140 |    899.517376 |     22.619769 | Matt Crook                                                                                                                                                            |
| 141 |     57.777977 |    780.139792 | Margot Michaud                                                                                                                                                        |
| 142 |    860.727266 |    471.952019 | Scott Hartman                                                                                                                                                         |
| 143 |    456.722297 |    681.283986 | NA                                                                                                                                                                    |
| 144 |     22.238467 |    268.778041 | Steven Traver                                                                                                                                                         |
| 145 |    294.198870 |    392.115314 | Daniel Jaron                                                                                                                                                          |
| 146 |    793.510857 |    736.602828 | Scott Hartman                                                                                                                                                         |
| 147 |    789.274006 |    679.340563 | Yan Wong from illustration by Charles Orbigny                                                                                                                         |
| 148 |     19.132434 |    724.821152 | Melissa Broussard                                                                                                                                                     |
| 149 |    375.900395 |    594.666915 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 150 |    562.316061 |    678.641310 | Armin Reindl                                                                                                                                                          |
| 151 |    249.851860 |    354.302320 | NA                                                                                                                                                                    |
| 152 |     79.716039 |    153.615552 | Margot Michaud                                                                                                                                                        |
| 153 |    358.130001 |    219.711034 | Gareth Monger                                                                                                                                                         |
| 154 |    647.245857 |    101.148973 | Steven Traver                                                                                                                                                         |
| 155 |     44.600523 |    596.221627 | Adam Stuart Smith (vectorized by T. Michael Keesey)                                                                                                                   |
| 156 |    192.177829 |     39.349551 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
| 157 |   1001.562081 |    266.446145 | NA                                                                                                                                                                    |
| 158 |    106.600896 |    209.710187 | Kamil S. Jaron                                                                                                                                                        |
| 159 |    451.049987 |     54.015856 | Jagged Fang Designs                                                                                                                                                   |
| 160 |    763.940066 |    322.552284 | Margot Michaud                                                                                                                                                        |
| 161 |    635.444163 |    516.770282 | Steven Traver                                                                                                                                                         |
| 162 |    358.554640 |    278.848286 | Roberto Díaz Sibaja                                                                                                                                                   |
| 163 |    148.501515 |    355.551166 | Andy Wilson                                                                                                                                                           |
| 164 |    264.978641 |    673.445893 | Matt Crook                                                                                                                                                            |
| 165 |    156.788037 |     44.833453 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                  |
| 166 |    689.617126 |    151.483158 | MPF (vectorized by T. Michael Keesey)                                                                                                                                 |
| 167 |    239.258788 |    605.752511 | Armin Reindl                                                                                                                                                          |
| 168 |    867.341666 |    450.610433 | C. Abraczinskas                                                                                                                                                       |
| 169 |    770.965555 |     79.092547 | Michael Scroggie                                                                                                                                                      |
| 170 |    369.014054 |    405.798486 | Zimices                                                                                                                                                               |
| 171 |    756.336994 |    632.663998 | Andy Wilson                                                                                                                                                           |
| 172 |    760.011933 |    537.779099 | Matt Crook                                                                                                                                                            |
| 173 |    828.619434 |    117.948697 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey       |
| 174 |    463.604548 |    190.321662 | Cagri Cevrim                                                                                                                                                          |
| 175 |    135.263115 |    467.616697 | Melissa Broussard                                                                                                                                                     |
| 176 |     71.523156 |    135.312545 | Ferran Sayol                                                                                                                                                          |
| 177 |    788.271032 |    476.523671 | Matt Crook                                                                                                                                                            |
| 178 |    449.840645 |    331.258403 | Zimices                                                                                                                                                               |
| 179 |    984.397755 |    449.911147 | Markus A. Grohme                                                                                                                                                      |
| 180 |    191.446133 |    264.221864 | Matt Crook                                                                                                                                                            |
| 181 |    834.433474 |    318.381772 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 182 |    784.006549 |    412.191361 | Yan Wong from photo by Denes Emoke                                                                                                                                    |
| 183 |    695.328304 |     33.358861 | Markus A. Grohme                                                                                                                                                      |
| 184 |     58.922930 |     96.046561 | Matt Crook                                                                                                                                                            |
| 185 |    475.605259 |    514.658935 | Maija Karala                                                                                                                                                          |
| 186 |    888.179854 |     45.406783 | Zimices                                                                                                                                                               |
| 187 |    816.983083 |    243.922103 | S.Martini                                                                                                                                                             |
| 188 |    993.620804 |    288.778328 | Harold N Eyster                                                                                                                                                       |
| 189 |    358.702640 |    770.220240 | C. Camilo Julián-Caballero                                                                                                                                            |
| 190 |    967.859891 |     18.622870 | Ferran Sayol                                                                                                                                                          |
| 191 |    998.023420 |    371.169668 | Matt Crook                                                                                                                                                            |
| 192 |    187.231930 |     74.805041 | Margot Michaud                                                                                                                                                        |
| 193 |    683.613329 |    275.440136 | Tasman Dixon                                                                                                                                                          |
| 194 |    504.272462 |    754.179489 | Kamil S. Jaron                                                                                                                                                        |
| 195 |    391.526457 |    375.578920 | Blanco et al., 2014, vectorized by Zimices                                                                                                                            |
| 196 |    521.623627 |    190.880742 | Scott Hartman                                                                                                                                                         |
| 197 |    423.378322 |    348.711020 | Gareth Monger                                                                                                                                                         |
| 198 |     99.907305 |    674.824723 | Notafly (vectorized by T. Michael Keesey)                                                                                                                             |
| 199 |    874.151131 |     22.733538 | Markus A. Grohme                                                                                                                                                      |
| 200 |    980.865673 |    680.339090 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 201 |    730.137010 |     12.437447 | Matt Crook                                                                                                                                                            |
| 202 |    599.810469 |    281.077388 | Xavier Giroux-Bougard                                                                                                                                                 |
| 203 |     49.076297 |    449.190146 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                                       |
| 204 |    255.111371 |    292.077140 | Gareth Monger                                                                                                                                                         |
| 205 |    124.867867 |    621.419257 | Margot Michaud                                                                                                                                                        |
| 206 |    663.890942 |    789.905553 | RS                                                                                                                                                                    |
| 207 |    550.964748 |    141.185992 | Jagged Fang Designs                                                                                                                                                   |
| 208 |    429.430426 |    454.120175 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 209 |    468.524022 |    269.403388 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 210 |    691.228542 |    400.706031 | Natasha Vitek                                                                                                                                                         |
| 211 |    292.224920 |    769.862375 | Kanchi Nanjo                                                                                                                                                          |
| 212 |   1006.905376 |     13.497944 | Yan Wong                                                                                                                                                              |
| 213 |    679.229923 |     45.979019 | Tony Ayling                                                                                                                                                           |
| 214 |    786.114251 |    738.358450 | Jagged Fang Designs                                                                                                                                                   |
| 215 |     26.831106 |    320.897549 | Matt Crook                                                                                                                                                            |
| 216 |    984.052704 |    512.058571 | David Orr                                                                                                                                                             |
| 217 |    922.458069 |    315.294479 | Lauren Anderson                                                                                                                                                       |
| 218 |    419.236480 |    765.792289 | Gareth Monger                                                                                                                                                         |
| 219 |    263.833583 |    308.647735 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 220 |    226.906191 |    761.926124 | Griensteidl and T. Michael Keesey                                                                                                                                     |
| 221 |    842.310869 |    716.124028 | NA                                                                                                                                                                    |
| 222 |   1008.457301 |    392.977761 | Andrew A. Farke                                                                                                                                                       |
| 223 |    566.232846 |    461.614124 | Steven Traver                                                                                                                                                         |
| 224 |    680.185256 |    206.700114 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 225 |    991.401603 |    223.537576 | Markus A. Grohme                                                                                                                                                      |
| 226 |     18.013603 |    558.485945 | Noah Schlottman                                                                                                                                                       |
| 227 |    255.670980 |    785.475300 | Dexter R. Mardis                                                                                                                                                      |
| 228 |    806.083502 |    438.785568 | Margot Michaud                                                                                                                                                        |
| 229 |    892.139846 |     66.178132 | Steven Traver                                                                                                                                                         |
| 230 |    892.607296 |    307.889067 | Scott Hartman                                                                                                                                                         |
| 231 |    689.380382 |    434.579806 | Smokeybjb, vectorized by Zimices                                                                                                                                      |
| 232 |    411.439149 |     70.510421 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 233 |    926.820611 |    425.186970 | NA                                                                                                                                                                    |
| 234 |     62.893576 |      9.266508 | Tracy A. Heath                                                                                                                                                        |
| 235 |    984.643927 |    668.138444 | Scott Hartman, modified by T. Michael Keesey                                                                                                                          |
| 236 |    206.776642 |    742.232704 | NA                                                                                                                                                                    |
| 237 |    396.910021 |    464.077190 | T. Michael Keesey (after Walker & al.)                                                                                                                                |
| 238 |    997.204533 |     82.729612 | Gareth Monger                                                                                                                                                         |
| 239 |    238.402744 |    479.743774 | Jagged Fang Designs                                                                                                                                                   |
| 240 |    331.051493 |     67.292284 | Henry Lydecker                                                                                                                                                        |
| 241 |    931.231285 |    595.840983 | Margot Michaud                                                                                                                                                        |
| 242 |    982.500869 |    148.791668 | Tauana J. Cunha                                                                                                                                                       |
| 243 |    687.836430 |    476.382839 | Matt Crook                                                                                                                                                            |
| 244 |     98.716009 |     13.505206 | Tasman Dixon                                                                                                                                                          |
| 245 |    409.867797 |    162.977894 | Ignacio Contreras                                                                                                                                                     |
| 246 |    204.471436 |    397.539990 | Zimices                                                                                                                                                               |
| 247 |    162.868636 |    424.325138 | Margot Michaud                                                                                                                                                        |
| 248 |    231.601878 |     42.171949 | Steven Traver                                                                                                                                                         |
| 249 |    268.341718 |    125.773782 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
| 250 |    121.927198 |    238.422472 | Jagged Fang Designs                                                                                                                                                   |
| 251 |    160.769457 |    512.438154 | Pete Buchholz                                                                                                                                                         |
| 252 |    419.626181 |    140.416729 | Matt Crook                                                                                                                                                            |
| 253 |    200.888505 |    488.544215 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                         |
| 254 |    783.274696 |    459.092007 | Carlos Cano-Barbacil                                                                                                                                                  |
| 255 |    842.432009 |    337.311644 | Gareth Monger                                                                                                                                                         |
| 256 |    104.586898 |    397.047764 | Gopal Murali                                                                                                                                                          |
| 257 |    726.321762 |    770.682330 | Roberto Díaz Sibaja                                                                                                                                                   |
| 258 |    398.601302 |    688.320813 | Zimices                                                                                                                                                               |
| 259 |     32.638993 |    300.762565 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 260 |     20.077927 |    774.083480 | Dean Schnabel                                                                                                                                                         |
| 261 |     64.718286 |    327.182363 | Juan Carlos Jerí                                                                                                                                                      |
| 262 |    599.699400 |    750.169244 | Tasman Dixon                                                                                                                                                          |
| 263 |    577.540880 |    150.543661 | Kimberly Haddrell                                                                                                                                                     |
| 264 |    497.245909 |    155.728256 | Richard Ruggiero, vectorized by Zimices                                                                                                                               |
| 265 |    456.907761 |    169.461184 | Iain Reid                                                                                                                                                             |
| 266 |    853.330777 |     32.843789 | Jagged Fang Designs                                                                                                                                                   |
| 267 |    856.270933 |      8.079919 | Zimices                                                                                                                                                               |
| 268 |     47.914291 |    756.889106 | Chris huh                                                                                                                                                             |
| 269 |    263.405087 |    167.469664 | Mathew Wedel                                                                                                                                                          |
| 270 |     16.361855 |    209.811767 | Mateus Zica (modified by T. Michael Keesey)                                                                                                                           |
| 271 |     22.405745 |    239.402664 | Margot Michaud                                                                                                                                                        |
| 272 |    277.670994 |    613.848159 | Mark Hannaford (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 273 |    348.890262 |    786.867788 | CNZdenek                                                                                                                                                              |
| 274 |    500.301837 |    529.808999 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 275 |    768.982790 |    281.896186 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
| 276 |    859.413245 |    136.842483 | Tracy A. Heath                                                                                                                                                        |
| 277 |    760.765347 |    265.862837 | Scott Hartman                                                                                                                                                         |
| 278 |    690.224863 |    753.174574 | Yan Wong                                                                                                                                                              |
| 279 |    775.643182 |    373.281182 | Michelle Site                                                                                                                                                         |
| 280 |    261.733036 |     15.061679 | Ferran Sayol                                                                                                                                                          |
| 281 |    444.499329 |    748.239191 | Rainer Schoch                                                                                                                                                         |
| 282 |    231.444022 |    373.886064 | Henry Lydecker                                                                                                                                                        |
| 283 |    736.959682 |    671.891386 | NA                                                                                                                                                                    |
| 284 |    733.110602 |    297.096594 | Matt Crook                                                                                                                                                            |
| 285 |     17.567733 |    697.876263 | Yan Wong from drawing by Joseph Smit                                                                                                                                  |
| 286 |    610.927494 |    315.344606 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 287 |    696.221998 |    503.299930 | Gareth Monger                                                                                                                                                         |
| 288 |    703.942416 |    113.603210 | Birgit Lang                                                                                                                                                           |
| 289 |    474.042155 |    531.709191 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 290 |    869.393672 |    209.824056 | Ricardo Araújo                                                                                                                                                        |
| 291 |    839.366928 |    563.126181 | xgirouxb                                                                                                                                                              |
| 292 |    108.545056 |    171.711368 | Ignacio Contreras                                                                                                                                                     |
| 293 |    146.468286 |    133.172998 | Skye M                                                                                                                                                                |
| 294 |     20.839124 |    155.499850 | NA                                                                                                                                                                    |
| 295 |    831.155569 |     42.018390 | Tasman Dixon                                                                                                                                                          |
| 296 |    137.197239 |     82.737026 | T. Michael Keesey                                                                                                                                                     |
| 297 |    635.431393 |    284.854416 | C. Camilo Julián-Caballero                                                                                                                                            |
| 298 |    622.757508 |    202.604366 | Margot Michaud                                                                                                                                                        |
| 299 |   1002.227083 |    313.567958 | T. Michael Keesey (after Marek Velechovský)                                                                                                                           |
| 300 |    777.249068 |    435.190246 | T. Michael Keesey                                                                                                                                                     |
| 301 |    960.060916 |    400.950797 | NA                                                                                                                                                                    |
| 302 |    213.237753 |    517.237978 | Ferran Sayol                                                                                                                                                          |
| 303 |    655.402539 |    701.476603 | T. Michael Keesey (after Kukalová)                                                                                                                                    |
| 304 |   1004.659875 |    165.461678 | Ferran Sayol                                                                                                                                                          |
| 305 |    962.040032 |    606.988219 | Zimices                                                                                                                                                               |
| 306 |    890.442052 |    326.634872 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 307 |    605.719272 |    695.656076 | Rebecca Groom                                                                                                                                                         |
| 308 |    992.231477 |    357.374682 | Heinrich Harder (vectorized by William Gearty)                                                                                                                        |
| 309 |    266.599989 |    423.422345 | Dmitry Bogdanov                                                                                                                                                       |
| 310 |    153.623606 |     92.543308 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 311 |    294.253172 |    121.418151 | Gopal Murali                                                                                                                                                          |
| 312 |    744.001217 |    518.851423 | Margot Michaud                                                                                                                                                        |
| 313 |    764.025744 |    470.497520 | NA                                                                                                                                                                    |
| 314 |    494.657624 |    187.193187 | Andy Wilson                                                                                                                                                           |
| 315 |    575.744799 |     62.974129 | Margot Michaud                                                                                                                                                        |
| 316 |    524.655214 |    684.183978 | Jagged Fang Designs                                                                                                                                                   |
| 317 |    441.202323 |    162.053428 | Birgit Lang                                                                                                                                                           |
| 318 |    542.321448 |    397.416616 | T. Michael Keesey (after James & al.)                                                                                                                                 |
| 319 |    436.371034 |    554.470827 | \<U+0414\>\<U+0438\>\<U+0411\>\<U+0433\>\<U+0434\> (vectorized by T. Michael Keesey)                                                                                  |
| 320 |     21.398270 |    351.635571 | Matt Crook                                                                                                                                                            |
| 321 |    554.303837 |    483.059207 | Yan Wong                                                                                                                                                              |
| 322 |    148.724758 |    501.603723 | Mattia Menchetti / Yan Wong                                                                                                                                           |
| 323 |    526.211669 |    264.376351 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 324 |    479.137056 |      5.230408 | Markus A. Grohme                                                                                                                                                      |
| 325 |    211.467727 |    793.627259 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                                   |
| 326 |    697.063024 |    197.007631 | S.Martini                                                                                                                                                             |
| 327 |    414.640667 |    673.483233 | Jack Mayer Wood                                                                                                                                                       |
| 328 |    424.861025 |    316.755912 | Ferran Sayol                                                                                                                                                          |
| 329 |    324.546426 |    362.747911 | Gareth Monger                                                                                                                                                         |
| 330 |     24.153200 |    577.673785 | Kai R. Caspar                                                                                                                                                         |
| 331 |    455.906804 |    733.448029 | Tracy A. Heath                                                                                                                                                        |
| 332 |     32.482731 |    747.432359 | Tasman Dixon                                                                                                                                                          |
| 333 |    380.122203 |    707.066731 | Zimices                                                                                                                                                               |
| 334 |   1007.321569 |    524.518480 | Dean Schnabel                                                                                                                                                         |
| 335 |    266.564018 |    328.328848 | Steven Traver                                                                                                                                                         |
| 336 |    681.850504 |    101.520609 | T. Michael Keesey                                                                                                                                                     |
| 337 |    515.929344 |    653.132576 | Zimices                                                                                                                                                               |
| 338 |    891.512277 |    748.101222 | Jagged Fang Designs                                                                                                                                                   |
| 339 |    198.226376 |     90.127390 | Ferran Sayol                                                                                                                                                          |
| 340 |    669.460072 |    286.432372 | Steven Traver                                                                                                                                                         |
| 341 |    436.579192 |    607.243762 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 342 |    937.231430 |     24.254676 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 343 |    498.283847 |    259.213507 | Gareth Monger                                                                                                                                                         |
| 344 |    512.225362 |    671.624319 | Melissa Broussard                                                                                                                                                     |
| 345 |    255.298105 |     32.657848 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 346 |    336.019619 |    667.831512 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 347 |    565.351154 |    392.520102 | Felix Vaux and Steven A. Trewick                                                                                                                                      |
| 348 |    822.150597 |    431.702961 | Jagged Fang Designs                                                                                                                                                   |
| 349 |     18.969589 |    526.606352 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                                     |
| 350 |    296.698066 |    277.286865 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 351 |    121.311521 |     35.672180 | Noah Schlottman                                                                                                                                                       |
| 352 |     50.945119 |    733.069812 | Gareth Monger                                                                                                                                                         |
| 353 |    901.515058 |    134.737295 | Birgit Lang                                                                                                                                                           |
| 354 |    275.882154 |    629.073010 | Jagged Fang Designs                                                                                                                                                   |
| 355 |    680.351188 |    264.547990 | Ignacio Contreras                                                                                                                                                     |
| 356 |    948.057319 |    131.413446 | Scott Hartman                                                                                                                                                         |
| 357 |    623.282819 |     76.770220 | Gordon E. Robertson                                                                                                                                                   |
| 358 |    625.440927 |    461.921282 | Emily Willoughby                                                                                                                                                      |
| 359 |    292.086799 |    724.299636 | Zimices                                                                                                                                                               |
| 360 |    551.531202 |    662.867411 | Dean Schnabel                                                                                                                                                         |
| 361 |    701.449740 |     10.538887 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 362 |    733.770892 |    108.319041 | CDC (Alissa Eckert; Dan Higgins)                                                                                                                                      |
| 363 |    812.112190 |    789.596827 | Tasman Dixon                                                                                                                                                          |
| 364 |    174.493194 |    724.983321 | Iain Reid                                                                                                                                                             |
| 365 |    671.823868 |     12.005964 | NA                                                                                                                                                                    |
| 366 |    178.413320 |    296.229925 | Zimices                                                                                                                                                               |
| 367 |    523.130088 |    406.922444 | Michael P. Taylor                                                                                                                                                     |
| 368 |    103.041406 |    440.889870 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 369 |    813.648172 |    644.141734 | Chris huh                                                                                                                                                             |
| 370 |    909.851656 |    302.727947 | Jagged Fang Designs                                                                                                                                                   |
| 371 |    156.637923 |    490.049765 | FunkMonk                                                                                                                                                              |
| 372 |    117.366157 |    354.378082 | Scott Hartman                                                                                                                                                         |
| 373 |    736.040023 |    333.808688 | Ferran Sayol                                                                                                                                                          |
| 374 |    973.891883 |    543.904107 | Gareth Monger                                                                                                                                                         |
| 375 |    629.634844 |    748.647255 | C. Camilo Julián-Caballero                                                                                                                                            |
| 376 |    151.993955 |    174.708335 | Melissa Broussard                                                                                                                                                     |
| 377 |    136.862781 |     60.449219 | Margot Michaud                                                                                                                                                        |
| 378 |     93.506147 |    456.140201 | Margot Michaud                                                                                                                                                        |
| 379 |    198.532144 |    760.004780 | Gareth Monger                                                                                                                                                         |
| 380 |    285.672465 |    294.754208 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                                           |
| 381 |    972.896873 |     58.682761 | Scott Hartman                                                                                                                                                         |
| 382 |    427.868013 |    394.609736 | Oscar Sanisidro                                                                                                                                                       |
| 383 |    195.926310 |    237.973596 | Andy Wilson                                                                                                                                                           |
| 384 |     39.911637 |    226.977540 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 385 |    529.067795 |    766.337038 | Chris huh                                                                                                                                                             |
| 386 |    123.320104 |    671.993286 | Harold N Eyster                                                                                                                                                       |
| 387 |    581.816256 |     12.895916 | Steven Coombs                                                                                                                                                         |
| 388 |    565.754113 |    769.243679 | Dmitry Bogdanov                                                                                                                                                       |
| 389 |    731.040750 |     38.854024 | NA                                                                                                                                                                    |
| 390 |    921.082279 |    405.142466 | NA                                                                                                                                                                    |
| 391 |    863.433746 |    320.977386 | U.S. National Park Service (vectorized by William Gearty)                                                                                                             |
| 392 |    163.175763 |    375.032598 | NA                                                                                                                                                                    |
| 393 |   1017.351651 |    599.956647 | Martin R. Smith                                                                                                                                                       |
| 394 |   1002.478577 |    671.839777 | Markus A. Grohme                                                                                                                                                      |
| 395 |     56.927409 |     73.332036 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 396 |    130.706775 |    598.465025 | Catherine Yasuda                                                                                                                                                      |
| 397 |    689.564674 |    788.191739 | Ferran Sayol                                                                                                                                                          |
| 398 |    323.969078 |    337.537758 | Margot Michaud                                                                                                                                                        |
| 399 |    256.038852 |    655.117961 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                         |
| 400 |   1000.314635 |    336.386521 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                                     |
| 401 |     69.946967 |     23.849289 | Jagged Fang Designs                                                                                                                                                   |
| 402 |    601.401698 |    331.501329 | Iain Reid                                                                                                                                                             |
| 403 |    762.107630 |    480.534179 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 404 |    783.501149 |     50.719035 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 405 |    810.219925 |    692.329014 | Kai R. Caspar                                                                                                                                                         |
| 406 |    506.307660 |    514.511449 | Tasman Dixon                                                                                                                                                          |
| 407 |    668.617382 |    196.713603 | Jagged Fang Designs                                                                                                                                                   |
| 408 |    328.672484 |    684.065791 | Mathew Wedel                                                                                                                                                          |
| 409 |    871.864043 |    355.446415 | FunkMonk                                                                                                                                                              |
| 410 |    152.937375 |    195.630734 | B. Duygu Özpolat                                                                                                                                                      |
| 411 |    956.457249 |    583.457776 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 412 |    385.322936 |    363.939970 | Tyler McCraney                                                                                                                                                        |
| 413 |    205.862566 |    224.144170 | Chris huh                                                                                                                                                             |
| 414 |    188.806263 |    745.369564 | Andy Wilson                                                                                                                                                           |
| 415 |    112.666236 |    223.371743 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 416 |    638.184290 |    188.698678 | Gareth Monger                                                                                                                                                         |
| 417 |     57.321415 |    716.466867 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 418 |    920.739729 |    438.971717 | Tasman Dixon                                                                                                                                                          |
| 419 |    370.194468 |    629.648214 | Gareth Monger                                                                                                                                                         |
| 420 |    576.804045 |    425.275415 | Andy Wilson                                                                                                                                                           |
| 421 |    353.082994 |    174.425611 | Markus A. Grohme                                                                                                                                                      |
| 422 |    180.956907 |    283.065762 | Steven Coombs                                                                                                                                                         |
| 423 |     15.279810 |    793.196183 | Matt Dempsey                                                                                                                                                          |
| 424 |    760.423407 |    416.661128 | Ferran Sayol                                                                                                                                                          |
| 425 |     20.122964 |    616.683052 | Tauana J. Cunha                                                                                                                                                       |
| 426 |     75.056072 |    184.906399 | Chris huh                                                                                                                                                             |
| 427 |    251.517107 |    135.453733 | Scott Hartman                                                                                                                                                         |
| 428 |    905.121461 |    606.200273 | Scott Hartman                                                                                                                                                         |
| 429 |    709.124276 |    285.580281 | Christine Axon                                                                                                                                                        |
| 430 |    771.727608 |    695.336475 | Gareth Monger                                                                                                                                                         |
| 431 |    758.193142 |    759.414443 | Gareth Monger                                                                                                                                                         |
| 432 |   1007.666307 |     30.829269 | John Conway                                                                                                                                                           |
| 433 |     64.499262 |    206.964557 | Amanda Katzer                                                                                                                                                         |
| 434 |    917.295773 |    518.356520 | FunkMonk                                                                                                                                                              |
| 435 |    758.165585 |    210.260328 | Michael Scroggie                                                                                                                                                      |
| 436 |    558.477830 |     75.201269 | Markus A. Grohme                                                                                                                                                      |
| 437 |    326.535049 |    466.522145 | Tyler Greenfield                                                                                                                                                      |
| 438 |    131.481948 |     71.779836 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                                 |
| 439 |    575.627743 |    788.739605 | FunkMonk                                                                                                                                                              |
| 440 |    529.547413 |    184.156400 | Gareth Monger                                                                                                                                                         |
| 441 |     74.991782 |    465.088658 | Jagged Fang Designs                                                                                                                                                   |
| 442 |    368.919625 |    232.295643 | Collin Gross                                                                                                                                                          |
| 443 |    119.666769 |    158.202044 | Gareth Monger                                                                                                                                                         |
| 444 |   1003.910533 |    621.795215 | T. Michael Keesey                                                                                                                                                     |
| 445 |    133.424199 |    116.037975 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 446 |    748.094120 |    281.460235 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 447 |    264.980080 |    276.402413 | Charles R. Knight, vectorized by Zimices                                                                                                                              |
| 448 |    361.439782 |    427.847341 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                       |
| 449 |    181.582831 |    325.852814 | T. Michael Keesey                                                                                                                                                     |
| 450 |    824.720834 |    490.745100 | Gareth Monger                                                                                                                                                         |
| 451 |    660.336073 |    685.979903 | Chris huh                                                                                                                                                             |
| 452 |    949.657075 |     68.627018 | Daniel Stadtmauer                                                                                                                                                     |
| 453 |    605.551243 |    237.727743 | Steven Coombs                                                                                                                                                         |
| 454 |    217.686021 |    534.407224 | Jaime Headden                                                                                                                                                         |
| 455 |    948.110865 |    522.019488 | Julie Blommaert based on photo by Sofdrakou                                                                                                                           |
| 456 |    290.948777 |    179.565537 | NA                                                                                                                                                                    |
| 457 |   1008.060703 |    129.076606 | Nobu Tamura                                                                                                                                                           |
| 458 |     55.222681 |    399.818118 | Margot Michaud                                                                                                                                                        |
| 459 |    469.080778 |    750.712423 | Cesar Julian                                                                                                                                                          |
| 460 |    873.501859 |    433.973187 | Dmitry Bogdanov                                                                                                                                                       |
| 461 |    754.989449 |    451.063352 | T. Michael Keesey                                                                                                                                                     |
| 462 |    708.809334 |    493.770720 | NA                                                                                                                                                                    |
| 463 |    398.979962 |    781.030486 | Jake Warner                                                                                                                                                           |
| 464 |    887.592198 |    373.175247 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 465 |    868.840104 |    754.139474 | Robert Hering                                                                                                                                                         |
| 466 |    463.638048 |    664.142827 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 467 |    174.024868 |    716.957383 | T. Tischler                                                                                                                                                           |
| 468 |   1008.189951 |    705.043062 | Michelle Site                                                                                                                                                         |
| 469 |     59.468770 |    118.704751 | S.Martini                                                                                                                                                             |
| 470 |    112.836006 |     28.587009 | Scott Hartman                                                                                                                                                         |
| 471 |    574.674616 |    325.180963 | Beth Reinke                                                                                                                                                           |
| 472 |    744.219017 |    353.366968 | Smokeybjb                                                                                                                                                             |
| 473 |    389.276960 |      8.974158 | Margot Michaud                                                                                                                                                        |
| 474 |    556.833838 |    204.666595 | Sarah Werning                                                                                                                                                         |
| 475 |    460.678075 |    564.189157 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 476 |    890.798395 |    594.082364 | T. Michael Keesey                                                                                                                                                     |
| 477 |    724.904470 |    762.559016 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 478 |    207.088975 |    653.952809 | Xavier Giroux-Bougard                                                                                                                                                 |
| 479 |    795.696535 |    723.992862 | Martin Kevil                                                                                                                                                          |
| 480 |   1003.828533 |    466.228962 | NA                                                                                                                                                                    |
| 481 |    571.415085 |    177.516722 | Michael Scroggie                                                                                                                                                      |
| 482 |    602.469538 |    733.110930 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 483 |    158.553073 |     69.355153 | Tasman Dixon                                                                                                                                                          |
| 484 |    210.042276 |    133.942302 | Jagged Fang Designs                                                                                                                                                   |
| 485 |   1006.940454 |    432.185970 | Steven Traver                                                                                                                                                         |
| 486 |    362.936437 |    671.646910 | Melissa Broussard                                                                                                                                                     |
| 487 |    304.772003 |    743.414145 | Margot Michaud                                                                                                                                                        |
| 488 |    571.568370 |    544.072134 | Katie S. Collins                                                                                                                                                      |
| 489 |    778.556115 |    404.229750 | Jagged Fang Designs                                                                                                                                                   |
| 490 |    749.589546 |    503.933485 | Gareth Monger                                                                                                                                                         |
| 491 |   1008.552877 |    782.794808 | Matt Crook                                                                                                                                                            |
| 492 |    744.236980 |    173.829607 | Erika Schumacher                                                                                                                                                      |
| 493 |    967.173866 |    375.963143 | Roberto Díaz Sibaja                                                                                                                                                   |
| 494 |    392.526893 |    606.454470 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 495 |    526.365402 |    151.619587 | NA                                                                                                                                                                    |
| 496 |    940.200249 |      4.462176 | Markus A. Grohme                                                                                                                                                      |
| 497 |    344.350893 |    155.833775 | Gareth Monger                                                                                                                                                         |
| 498 |      8.533876 |    468.020717 | Lukasiniho                                                                                                                                                            |
| 499 |    678.803312 |    665.364666 | Tony Ayling                                                                                                                                                           |
| 500 |    991.034714 |    502.713397 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 501 |    290.119374 |    560.561533 | NA                                                                                                                                                                    |
| 502 |    744.288330 |    315.429914 | Gareth Monger                                                                                                                                                         |
| 503 |    380.558872 |    580.222238 | Scott Hartman                                                                                                                                                         |
| 504 |    558.648063 |    120.893328 | Arthur S. Brum                                                                                                                                                        |
| 505 |    565.759958 |    446.125078 | T. Michael Keesey                                                                                                                                                     |
| 506 |    253.545818 |    694.889095 | Matt Dempsey                                                                                                                                                          |
| 507 |    613.689074 |    651.968651 | Collin Gross                                                                                                                                                          |
| 508 |    639.238826 |    168.717324 | T. Michael Keesey (after Marek Velechovský)                                                                                                                           |
| 509 |    947.402626 |    109.690501 | Steven Traver                                                                                                                                                         |
| 510 |    367.127884 |    418.089694 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 511 |    652.708352 |     25.447058 | Jake Warner                                                                                                                                                           |
| 512 |   1019.723976 |     73.234228 | Agnello Picorelli                                                                                                                                                     |
| 513 |    193.595542 |    649.975750 | Manabu Bessho-Uehara                                                                                                                                                  |
| 514 |    581.929197 |    756.272460 | Chris huh                                                                                                                                                             |
| 515 |    674.914618 |    251.924415 | Gareth Monger                                                                                                                                                         |
| 516 |    973.896948 |    421.019654 | Margot Michaud                                                                                                                                                        |
| 517 |    262.211983 |    462.697466 | Steven Coombs                                                                                                                                                         |
| 518 |     37.848106 |    551.696903 | Gareth Monger                                                                                                                                                         |
| 519 |    312.503629 |    714.305820 | Shyamal                                                                                                                                                               |
| 520 |    372.624795 |    465.408284 | Steven Traver                                                                                                                                                         |
| 521 |    537.891695 |      8.924014 | Scott Hartman                                                                                                                                                         |
| 522 |    214.607119 |    495.784072 | Jagged Fang Designs                                                                                                                                                   |
| 523 |   1006.071232 |    661.690651 | Markus A. Grohme                                                                                                                                                      |
| 524 |    180.071347 |    388.947863 | Matt Crook                                                                                                                                                            |
| 525 |     64.864496 |    753.130016 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 526 |    402.088429 |    619.072117 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 527 |    392.592058 |    408.610396 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 528 |    614.214393 |     94.866448 | Julio Garza                                                                                                                                                           |
| 529 |    816.654496 |    457.990207 | Steven Coombs                                                                                                                                                         |
| 530 |     67.920219 |    469.140418 | Scott Hartman                                                                                                                                                         |
| 531 |    600.680926 |    295.862339 | Tasman Dixon                                                                                                                                                          |
| 532 |    859.279932 |    520.052903 | FunkMonk                                                                                                                                                              |
| 533 |    593.425130 |    794.677019 | Tyler Greenfield                                                                                                                                                      |
| 534 |   1009.815162 |     58.530705 | Aviceda (photo) & T. Michael Keesey                                                                                                                                   |
| 535 |    425.996895 |    411.570372 | Markus A. Grohme                                                                                                                                                      |
| 536 |    343.421232 |    134.107833 | Dean Schnabel                                                                                                                                                         |
| 537 |    180.587362 |    360.220425 | Tasman Dixon                                                                                                                                                          |
| 538 |    176.744263 |    225.169285 | Alex Slavenko                                                                                                                                                         |
| 539 |    943.240981 |    227.796711 | NA                                                                                                                                                                    |

    #> Your tweet has been posted!
