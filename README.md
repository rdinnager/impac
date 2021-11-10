
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

Matthew Hooge (vectorized by T. Michael Keesey), Roberto Diaz Sibaja,
based on Domser, Margot Michaud, Scott Hartman, Wayne Decatur, Matt
Crook, Gareth Monger, David Orr, Becky Barnes, Chris huh, Gabriela
Palomo-Munoz, Joanna Wolfe, Lisa Byrne, Ferran Sayol, Elisabeth Östman,
Dean Schnabel, Robbie N. Cada (modified by T. Michael Keesey), Rene
Martin, Kent Elson Sorgon, T. Michael Keesey, Nobu Tamura (modified by
T. Michael Keesey), Jagged Fang Designs, Birgit Lang, Rebecca Groom,
Sarah Werning, Martin R. Smith, after Skovsted et al 2015, Mark
Hofstetter (vectorized by T. Michael Keesey), Zimices, White Wolf,
Chuanixn Yu, Berivan Temiz, Nobu Tamura (vectorized by T. Michael
Keesey), Philip Chalmers (vectorized by T. Michael Keesey), Henry
Fairfield Osborn, vectorized by Zimices, T. Tischler, Yan Wong from
drawing by T. F. Zimmermann, David Tana, Chloé Schmidt, Smokeybjb, Matt
Dempsey, FunkMonk, FunkMonk \[Michael B.H.\] (modified by T. Michael
Keesey), L. Shyamal, Emma Kissling, Steven Traver, Ludwik Gasiorowski,
Meliponicultor Itaymbere, Jake Warner, Original drawing by Dmitry
Bogdanov, vectorized by Roberto Díaz Sibaja, Melissa Broussard, Melissa
Ingala, Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant
C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield &
T. Michael Keesey, Geoff Shaw, Andrew A. Farke, Siobhon Egan, Robbie N.
Cada (vectorized by T. Michael Keesey), George Edward Lodge, Mathilde
Cordellier, Mali’o Kodis, image from the Smithsonian Institution, Ernst
Haeckel (vectorized by T. Michael Keesey), Emily Willoughby, Dein Freund
der Baum (vectorized by T. Michael Keesey), Mali’o Kodis, photograph by
Derek Keats (<http://www.flickr.com/photos/dkeats/>), Lafage, Hans
Hillewaert (vectorized by T. Michael Keesey), Griensteidl and T. Michael
Keesey, Christoph Schomburg, Mark Miller, T. Michael Keesey and
Tanetahi, Noah Schlottman, photo from Casey Dunn, Jessica Anne Miller,
Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey),
Michelle Site, Dmitry Bogdanov (vectorized by T. Michael Keesey), E. D.
Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J.
Wedel), C. Camilo Julián-Caballero, Dann Pigdon, Carlos Cano-Barbacil,
Matt Martyniuk, Tasman Dixon, Darren Naish (vectorized by T. Michael
Keesey), Noah Schlottman, photo by Casey Dunn, Sam Fraser-Smith
(vectorized by T. Michael Keesey), Dmitry Bogdanov, Fernando Carezzano,
L.M. Davalos, Manabu Bessho-Uehara, Scott Hartman (modified by T.
Michael Keesey), Martin R. Smith, Mali’o Kodis, image from the
“Proceedings of the Zoological Society of London”, Collin Gross, Yan
Wong, Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant
C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield &
T. Michael Keesey, Konsta Happonen, from a CC-BY-NC image by pelhonen on
iNaturalist, Fcb981 (vectorized by T. Michael Keesey), Maxime Dahirel,
Blair Perry, Smith609 and T. Michael Keesey, Alexander Schmidt-Lebuhn,
Zimices, based in Mauricio Antón skeletal, Mali’o Kodis, photograph by
Ching (<http://www.flickr.com/photos/36302473@N03/>), Emily Jane
McTavish, from
<http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>,
FJDegrange, Ray Simpson (vectorized by T. Michael Keesey), Kamil S.
Jaron, Josefine Bohr Brask, Yusan Yang, Michael Scroggie, from original
photograph by Gary M. Stolz, USFWS (original photograph in public
domain)., Darren Naish (vectorize by T. Michael Keesey), CNZdenek,
Didier Descouens (vectorized by T. Michael Keesey), Stacy Spensley
(Modified), Brockhaus and Efron, Scott D. Sampson, Mark A. Loewen,
Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith,
Alan L. Titus, Ieuan Jones, Renata F. Martins, Davidson Sodré, Matt
Martyniuk (vectorized by T. Michael Keesey), Falconaumanni and T.
Michael Keesey, Tomas Willems (vectorized by T. Michael Keesey), Maija
Karala, Ingo Braasch, Jakovche, Mali’o Kodis, photograph by P. Funch and
R.M. Kristensen, Cesar Julian, Ghedoghedo (vectorized by T. Michael
Keesey), Dave Angelini, Mason McNair, Roberto Díaz Sibaja, Apokryltaros
(vectorized by T. Michael Keesey), Beth Reinke, , Jose Carlos
Arenas-Monroy, Steven Coombs, Dmitry Bogdanov (modified by T. Michael
Keesey), Joris van der Ham (vectorized by T. Michael Keesey), Jonathan
Wells, J. J. Harrison (photo) & T. Michael Keesey, Benchill, Iain Reid,
Jaime Headden, \[unknown\], Pedro de Siracusa, Todd Marshall, vectorized
by Zimices, Katie S. Collins, Nobu Tamura, Milton Tan, Tim H. Heupink,
Leon Huynen, and David M. Lambert (vectorized by T. Michael Keesey),
Tony Ayling (vectorized by T. Michael Keesey), Karla Martinez, Jan A.
Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized
by T. Michael Keesey), Mali’o Kodis, image by Rebecca Ritger, Harold N
Eyster, (after Spotila 2004), Ellen Edmonson (illustration) and Timothy
J. Bartley (silhouette), Alex Slavenko, Luis Cunha, M Kolmann, Jay
Matternes, vectorized by Zimices, Mattia Menchetti, Michael Scroggie,
Lukasiniho, Francisco Manuel Blanco (vectorized by T. Michael Keesey),
Neil Kelley, Jan Sevcik (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Matt Wilkins, Qiang Ou, Crystal Maier,
Gustav Mützel, Sherman F. Denton via rawpixel.com (illustration) and
Timothy J. Bartley (silhouette), Taenadoman, Kanako Bessho-Uehara,
Burton Robert, USFWS, Lip Kee Yap (vectorized by T. Michael Keesey),
Mariana Ruiz Villarreal, Acrocynus (vectorized by T. Michael Keesey),
Anthony Caravaggi, Steven Coombs (vectorized by T. Michael Keesey),
Andrew A. Farke, shell lines added by Yan Wong, Armelle Ansart
(photograph), Maxime Dahirel (digitisation), Pete Buchholz, DW Bapst
(Modified from photograph taken by Charles Mitchell), Mathieu Basille,
Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary,
Mali’o Kodis, photograph from
<http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>, Matt Hayes,
Tracy A. Heath, Jon M Laurent, G. M. Woodward, Robert Bruce Horsfall,
vectorized by Zimices, Jonathan Lawley, Alan Manson (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Felix Vaux,
Steven Haddock • Jellywatch.org, Andrew A. Farke, modified from original
by Robert Bruce Horsfall, from Scott 1912, Shyamal, Christian A.
Masnaghetti, Noah Schlottman, photo by Carlos Sánchez-Ortiz, S.Martini,
Chris Jennings (Risiatto), Roger Witter, vectorized by Zimices, H.
Filhol (vectorized by T. Michael Keesey), Plukenet, U.S. Fish and
Wildlife Service (illustration) and Timothy J. Bartley (silhouette),
Ricardo Araújo, Theodore W. Pietsch (photography) and T. Michael Keesey
(vectorization), . Original drawing by M. Antón, published in Montoya
and Morales 1984. Vectorized by O. Sanisidro, Tyler Greenfield,
Benjamint444, Inessa Voet, Ryan Cupo, Richard Parker (vectorized by T.
Michael Keesey), T. Michael Keesey (from a mount by Allis Markham),
Metalhead64 (vectorized by T. Michael Keesey), Haplochromis (vectorized
by T. Michael Keesey), Yan Wong from illustration by Jules Richard
(1907), Nicolas Mongiardino Koch, Sergio A. Muñoz-Gómez, Matus Valach,
Nobu Tamura, vectorized by Zimices, Don Armstrong, Obsidian Soul
(vectorized by T. Michael Keesey), Francesco Veronesi (vectorized by T.
Michael Keesey), Kai R. Caspar, T. Michael Keesey (after Colin M. L.
Burnett), Amanda Katzer, Scarlet23 (vectorized by T. Michael Keesey),
Nobu Tamura (vectorized by A. Verrière), Chase Brownstein, Tom Tarrant
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Darius Nau, Young and Zhao (1972:figure 4), modified by Michael
P. Taylor, Jaime Headden (vectorized by T. Michael Keesey), Christopher
Laumer (vectorized by T. Michael Keesey), Mo Hassan, Duane Raver/USFWS,
Philippe Janvier (vectorized by T. Michael Keesey), John Curtis
(vectorized by T. Michael Keesey), James R. Spotila and Ray Chatterji,
Peileppe, Richard Lampitt, Jeremy Young / NHM (vectorization by Yan
Wong), Mike Hanson, Sean McCann, Sam Droege (photo) and T. Michael
Keesey (vectorization), Andreas Trepte (vectorized by T. Michael
Keesey), Smokeybjb (modified by T. Michael Keesey), Michael P. Taylor,
Yan Wong from drawing by Joseph Smit, Noah Schlottman, Aviceda (photo) &
T. Michael Keesey, Duane Raver (vectorized by T. Michael Keesey), T.
Michael Keesey (photo by Bc999 \[Black crow\]), Mali’o Kodis, drawing by
Manvir Singh, xgirouxb, E. J. Van Nieukerken, A. Laštuvka, and Z.
Laštuvka (vectorized by T. Michael Keesey), Craig Dylke, Caroline
Harding, MAF (vectorized by T. Michael Keesey), Xavier Giroux-Bougard,
Brad McFeeters (vectorized by T. Michael Keesey), Greg Schechter
(original photo), Renato Santos (vector silhouette), Ellen Edmonson and
Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette), Filip
em, Stemonitis (photography) and T. Michael Keesey (vectorization),
Óscar San-Isidro (vectorized by T. Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                      |
| --: | ------------: | ------------: | :---------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    598.268801 |    334.444953 | NA                                                                                                                                                          |
|   2 |    875.172656 |    552.716931 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                             |
|   3 |    791.860895 |    201.608799 | Roberto Diaz Sibaja, based on Domser                                                                                                                        |
|   4 |    771.346470 |    586.405810 | Margot Michaud                                                                                                                                              |
|   5 |    399.332244 |    535.192471 | Scott Hartman                                                                                                                                               |
|   6 |    148.024756 |    275.555035 | Margot Michaud                                                                                                                                              |
|   7 |    429.986166 |     78.161733 | Wayne Decatur                                                                                                                                               |
|   8 |    218.987780 |     65.173959 | NA                                                                                                                                                          |
|   9 |    294.640883 |    498.168681 | Matt Crook                                                                                                                                                  |
|  10 |    758.223310 |     55.755633 | Gareth Monger                                                                                                                                               |
|  11 |    943.941328 |    418.168814 | David Orr                                                                                                                                                   |
|  12 |    624.436850 |    505.200822 | Becky Barnes                                                                                                                                                |
|  13 |    269.059195 |    276.591220 | Margot Michaud                                                                                                                                              |
|  14 |    925.029240 |    649.046828 | Chris huh                                                                                                                                                   |
|  15 |    780.469219 |    716.131350 | Gabriela Palomo-Munoz                                                                                                                                       |
|  16 |    220.205399 |    669.159798 | Joanna Wolfe                                                                                                                                                |
|  17 |    820.226645 |    370.835157 | NA                                                                                                                                                          |
|  18 |    101.948251 |    374.720916 | Lisa Byrne                                                                                                                                                  |
|  19 |    361.529929 |    752.815843 | NA                                                                                                                                                          |
|  20 |    509.528633 |    234.028578 | Ferran Sayol                                                                                                                                                |
|  21 |    898.319651 |    135.770015 | Scott Hartman                                                                                                                                               |
|  22 |    140.740449 |    700.833529 | Elisabeth Östman                                                                                                                                            |
|  23 |    619.795243 |     71.752337 | Dean Schnabel                                                                                                                                               |
|  24 |    131.024490 |    527.344568 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                              |
|  25 |    618.359580 |    717.483545 | Margot Michaud                                                                                                                                              |
|  26 |    320.654589 |    325.056894 | Matt Crook                                                                                                                                                  |
|  27 |    523.299757 |    615.561026 | Rene Martin                                                                                                                                                 |
|  28 |    493.120153 |    444.718547 | Matt Crook                                                                                                                                                  |
|  29 |    590.865705 |    191.393126 | Kent Elson Sorgon                                                                                                                                           |
|  30 |    717.832762 |    134.606292 | T. Michael Keesey                                                                                                                                           |
|  31 |    457.942689 |    331.911569 | T. Michael Keesey                                                                                                                                           |
|  32 |    270.184021 |    194.906733 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                 |
|  33 |    215.917900 |    572.794162 | Jagged Fang Designs                                                                                                                                         |
|  34 |    331.384199 |    124.991263 | Birgit Lang                                                                                                                                                 |
|  35 |    528.631682 |    740.240181 | Gareth Monger                                                                                                                                               |
|  36 |    660.920216 |    776.750637 | Rebecca Groom                                                                                                                                               |
|  37 |    927.946466 |    246.200837 | Sarah Werning                                                                                                                                               |
|  38 |    114.741202 |     95.233266 | Martin R. Smith, after Skovsted et al 2015                                                                                                                  |
|  39 |    536.257126 |    144.909374 | Jagged Fang Designs                                                                                                                                         |
|  40 |    971.928104 |    125.522803 | Mark Hofstetter (vectorized by T. Michael Keesey)                                                                                                           |
|  41 |    901.492296 |     50.304826 | Zimices                                                                                                                                                     |
|  42 |    264.255472 |    393.066744 | Zimices                                                                                                                                                     |
|  43 |    372.235074 |    626.185602 | White Wolf                                                                                                                                                  |
|  44 |    739.439188 |    638.108047 | Chuanixn Yu                                                                                                                                                 |
|  45 |    123.314235 |    438.617787 | Berivan Temiz                                                                                                                                               |
|  46 |    394.445206 |    218.376164 | Zimices                                                                                                                                                     |
|  47 |    493.920873 |    679.537166 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
|  48 |    650.578426 |    267.394622 | Matt Crook                                                                                                                                                  |
|  49 |     48.579345 |     75.636939 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                           |
|  50 |    637.612621 |    407.274626 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                               |
|  51 |    353.422139 |     34.188392 | T. Tischler                                                                                                                                                 |
|  52 |    295.389387 |    587.916141 | Chris huh                                                                                                                                                   |
|  53 |    331.197531 |    652.718725 | Scott Hartman                                                                                                                                               |
|  54 |     56.207186 |    236.670502 | Yan Wong from drawing by T. F. Zimmermann                                                                                                                   |
|  55 |    931.202803 |    734.103221 | David Tana                                                                                                                                                  |
|  56 |    626.750839 |    120.377067 | Chloé Schmidt                                                                                                                                               |
|  57 |    164.540484 |    173.889637 | Smokeybjb                                                                                                                                                   |
|  58 |    925.315309 |    779.833975 | Matt Dempsey                                                                                                                                                |
|  59 |    451.319253 |    169.142108 | Jagged Fang Designs                                                                                                                                         |
|  60 |    938.093110 |    684.379718 | FunkMonk                                                                                                                                                    |
|  61 |    602.702122 |     27.796834 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                   |
|  62 |    392.003662 |    412.209231 | L. Shyamal                                                                                                                                                  |
|  63 |    356.403690 |    682.164810 | Emma Kissling                                                                                                                                               |
|  64 |     89.432938 |    616.335129 | Steven Traver                                                                                                                                               |
|  65 |    728.427075 |    385.168263 | Ludwik Gasiorowski                                                                                                                                          |
|  66 |     51.078811 |    757.066179 | Meliponicultor Itaymbere                                                                                                                                    |
|  67 |    662.012742 |    662.759625 | Jake Warner                                                                                                                                                 |
|  68 |    954.052617 |    581.467848 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                      |
|  69 |    457.263865 |    123.304978 | Jagged Fang Designs                                                                                                                                         |
|  70 |    585.074367 |    244.847115 | Melissa Broussard                                                                                                                                           |
|  71 |    636.404257 |    444.410093 | Birgit Lang                                                                                                                                                 |
|  72 |    492.849472 |    534.626939 | Melissa Ingala                                                                                                                                              |
|  73 |    212.021707 |    235.554305 | Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
|  74 |    925.445843 |    171.041205 | Geoff Shaw                                                                                                                                                  |
|  75 |     87.656584 |    295.664871 | Gareth Monger                                                                                                                                               |
|  76 |    801.461687 |    123.508390 | Steven Traver                                                                                                                                               |
|  77 |    678.023680 |    616.887217 | Sarah Werning                                                                                                                                               |
|  78 |    788.916441 |    493.436321 | Andrew A. Farke                                                                                                                                             |
|  79 |     24.458258 |    690.883681 | NA                                                                                                                                                          |
|  80 |    642.935626 |    597.681566 | Siobhon Egan                                                                                                                                                |
|  81 |    506.067657 |    551.754821 | Gabriela Palomo-Munoz                                                                                                                                       |
|  82 |    623.421614 |    640.058828 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                            |
|  83 |     43.909088 |    415.511931 | George Edward Lodge                                                                                                                                         |
|  84 |    590.102958 |    574.516123 | Mathilde Cordellier                                                                                                                                         |
|  85 |    267.429572 |     20.011705 | NA                                                                                                                                                          |
|  86 |    893.308349 |    201.898942 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                        |
|  87 |   1007.647139 |     27.066238 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                             |
|  88 |    999.328601 |    260.269909 | Matt Crook                                                                                                                                                  |
|  89 |    520.516162 |    476.071064 | Gabriela Palomo-Munoz                                                                                                                                       |
|  90 |    881.539668 |    411.107974 | Gabriela Palomo-Munoz                                                                                                                                       |
|  91 |    209.541322 |    468.289276 | Melissa Broussard                                                                                                                                           |
|  92 |    236.764847 |    347.094542 | Dean Schnabel                                                                                                                                               |
|  93 |    319.821401 |     81.589230 | T. Michael Keesey                                                                                                                                           |
|  94 |    987.980894 |    536.888475 | Emily Willoughby                                                                                                                                            |
|  95 |    415.294372 |    126.999876 | Gareth Monger                                                                                                                                               |
|  96 |    269.733873 |    126.866191 | Scott Hartman                                                                                                                                               |
|  97 |    230.449906 |    720.981924 | Dein Freund der Baum (vectorized by T. Michael Keesey)                                                                                                      |
|  98 |    962.118288 |    567.835943 | Sarah Werning                                                                                                                                               |
|  99 |    891.686762 |    494.037290 | Mali’o Kodis, photograph by Derek Keats (<http://www.flickr.com/photos/dkeats/>)                                                                            |
| 100 |    257.948173 |    332.351065 | Lafage                                                                                                                                                      |
| 101 |    492.476100 |    515.623923 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                           |
| 102 |    585.997703 |    679.412292 | Gareth Monger                                                                                                                                               |
| 103 |    226.644710 |    610.898912 | Griensteidl and T. Michael Keesey                                                                                                                           |
| 104 |    818.862547 |    255.237705 | NA                                                                                                                                                          |
| 105 |     79.752044 |    172.484211 | Christoph Schomburg                                                                                                                                         |
| 106 |    453.481109 |    259.707918 | Mark Miller                                                                                                                                                 |
| 107 |    454.839243 |    522.706368 | Gareth Monger                                                                                                                                               |
| 108 |    710.179346 |    595.157064 | Margot Michaud                                                                                                                                              |
| 109 |    713.561399 |    295.277449 | Ferran Sayol                                                                                                                                                |
| 110 |    175.240564 |    110.864051 | Gabriela Palomo-Munoz                                                                                                                                       |
| 111 |    436.358651 |    249.958751 | Matt Crook                                                                                                                                                  |
| 112 |    398.375335 |    300.979125 | T. Michael Keesey and Tanetahi                                                                                                                              |
| 113 |    221.973541 |    442.138757 | Steven Traver                                                                                                                                               |
| 114 |     64.977979 |    787.240065 | Noah Schlottman, photo from Casey Dunn                                                                                                                      |
| 115 |    454.771821 |    474.458256 | Jessica Anne Miller                                                                                                                                         |
| 116 |     88.640475 |    318.752684 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                            |
| 117 |    157.563980 |     53.100179 | Dean Schnabel                                                                                                                                               |
| 118 |    670.998639 |    172.373621 | Michelle Site                                                                                                                                               |
| 119 |    525.278658 |    566.127004 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 120 |    500.229722 |    185.247135 | FunkMonk                                                                                                                                                    |
| 121 |    765.685704 |    514.878236 | Matt Crook                                                                                                                                                  |
| 122 |    917.280893 |    704.612946 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                            |
| 123 |    133.815166 |    306.311042 | C. Camilo Julián-Caballero                                                                                                                                  |
| 124 |    996.390955 |    192.796547 | Birgit Lang                                                                                                                                                 |
| 125 |    145.777313 |    134.254348 | Chloé Schmidt                                                                                                                                               |
| 126 |    886.019321 |    600.604589 | Dann Pigdon                                                                                                                                                 |
| 127 |    319.761053 |    340.669364 | Carlos Cano-Barbacil                                                                                                                                        |
| 128 |     72.411050 |    743.947465 | NA                                                                                                                                                          |
| 129 |    691.011559 |     91.780522 | Margot Michaud                                                                                                                                              |
| 130 |    824.031896 |     64.478241 | Zimices                                                                                                                                                     |
| 131 |     58.271359 |    153.047110 | Matt Martyniuk                                                                                                                                              |
| 132 |    875.452523 |    612.347617 | T. Tischler                                                                                                                                                 |
| 133 |    184.124287 |    612.414869 | NA                                                                                                                                                          |
| 134 |    730.256402 |    242.177732 | Tasman Dixon                                                                                                                                                |
| 135 |    761.228643 |    494.706921 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                              |
| 136 |    268.487443 |    109.512650 | Ferran Sayol                                                                                                                                                |
| 137 |    184.954082 |    306.198090 | Chris huh                                                                                                                                                   |
| 138 |    202.054384 |    376.786526 | Scott Hartman                                                                                                                                               |
| 139 |    789.660058 |    152.752631 | Zimices                                                                                                                                                     |
| 140 |    982.522813 |    666.573773 | Emily Willoughby                                                                                                                                            |
| 141 |     75.027802 |    474.654647 | Zimices                                                                                                                                                     |
| 142 |     52.406960 |    149.286421 | Noah Schlottman, photo by Casey Dunn                                                                                                                        |
| 143 |    764.843144 |    550.399003 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                          |
| 144 |    382.353952 |    332.149431 | Chris huh                                                                                                                                                   |
| 145 |    540.693359 |    461.073517 | Michelle Site                                                                                                                                               |
| 146 |    234.667296 |    390.339368 | Gabriela Palomo-Munoz                                                                                                                                       |
| 147 |    560.269248 |    377.855089 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 148 |    519.718661 |    114.551151 | Dmitry Bogdanov                                                                                                                                             |
| 149 |    781.605650 |     93.045037 | Fernando Carezzano                                                                                                                                          |
| 150 |    767.353903 |    794.759082 | Scott Hartman                                                                                                                                               |
| 151 |    843.715415 |     13.382993 | Margot Michaud                                                                                                                                              |
| 152 |    529.958920 |    103.356527 | L.M. Davalos                                                                                                                                                |
| 153 |    795.137359 |    480.362996 | Jagged Fang Designs                                                                                                                                         |
| 154 |    534.027975 |    233.220857 | Manabu Bessho-Uehara                                                                                                                                        |
| 155 |    767.964762 |    130.495256 | Margot Michaud                                                                                                                                              |
| 156 |    672.292872 |    567.512956 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                             |
| 157 |    824.123528 |     28.065453 | Matt Crook                                                                                                                                                  |
| 158 |    350.708491 |    187.533529 | Jagged Fang Designs                                                                                                                                         |
| 159 |     23.095229 |    309.720344 | Birgit Lang                                                                                                                                                 |
| 160 |    301.287839 |    349.304547 | Steven Traver                                                                                                                                               |
| 161 |    836.268771 |    777.018839 | Scott Hartman (modified by T. Michael Keesey)                                                                                                               |
| 162 |     47.262896 |    718.198226 | Martin R. Smith                                                                                                                                             |
| 163 |    876.364479 |    457.678411 | NA                                                                                                                                                          |
| 164 |    433.076616 |    593.447484 | Mali’o Kodis, image from the “Proceedings of the Zoological Society of London”                                                                              |
| 165 |     49.671005 |    702.226169 | Steven Traver                                                                                                                                               |
| 166 |   1003.282551 |    236.691449 | Gareth Monger                                                                                                                                               |
| 167 |    749.556216 |    478.326814 | Scott Hartman                                                                                                                                               |
| 168 |     13.049876 |    210.827618 | Matt Crook                                                                                                                                                  |
| 169 |    338.121196 |    242.492630 | Collin Gross                                                                                                                                                |
| 170 |     33.668071 |    434.310828 | Gareth Monger                                                                                                                                               |
| 171 |    723.478005 |    192.364890 | Yan Wong                                                                                                                                                    |
| 172 |    731.556005 |    779.459022 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 173 |    177.479249 |    130.624511 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                           |
| 174 |    774.271642 |     24.826543 | Fcb981 (vectorized by T. Michael Keesey)                                                                                                                    |
| 175 |    986.619384 |    412.079440 | Maxime Dahirel                                                                                                                                              |
| 176 |    686.536625 |    152.880450 | Matt Crook                                                                                                                                                  |
| 177 |     34.665596 |    480.795292 | Chris huh                                                                                                                                                   |
| 178 |     21.286175 |     36.543952 | T. Michael Keesey                                                                                                                                           |
| 179 |    862.892075 |    224.296435 | Steven Traver                                                                                                                                               |
| 180 |    616.325232 |    267.052526 | David Orr                                                                                                                                                   |
| 181 |    237.428645 |    238.777997 | Blair Perry                                                                                                                                                 |
| 182 |    729.048885 |    532.674632 | Carlos Cano-Barbacil                                                                                                                                        |
| 183 |    244.573975 |    440.656209 | Matt Crook                                                                                                                                                  |
| 184 |    798.200992 |     19.025558 | T. Michael Keesey                                                                                                                                           |
| 185 |    798.330033 |    512.689878 | Gareth Monger                                                                                                                                               |
| 186 |    356.541385 |    424.777958 | Smith609 and T. Michael Keesey                                                                                                                              |
| 187 |    120.890820 |    652.078809 | Gareth Monger                                                                                                                                               |
| 188 |    756.867696 |    786.546057 | Zimices                                                                                                                                                     |
| 189 |    558.189528 |    442.616029 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 190 |    807.461224 |    571.949546 | Jake Warner                                                                                                                                                 |
| 191 |    757.401682 |    533.501468 | Alexander Schmidt-Lebuhn                                                                                                                                    |
| 192 |    638.938421 |    560.708586 | Zimices, based in Mauricio Antón skeletal                                                                                                                   |
| 193 |    995.400549 |    381.899049 | NA                                                                                                                                                          |
| 194 |     30.601815 |    151.424957 | Gareth Monger                                                                                                                                               |
| 195 |    686.972990 |    663.712747 | Zimices                                                                                                                                                     |
| 196 |     70.425967 |    750.774062 | Steven Traver                                                                                                                                               |
| 197 |     40.382184 |    557.462289 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 198 |    459.763318 |    724.910267 | Mali’o Kodis, photograph by Ching (<http://www.flickr.com/photos/36302473@N03/>)                                                                            |
| 199 |    855.150860 |     94.367667 | Emily Jane McTavish, from <http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>                                                                     |
| 200 |    766.556988 |    142.927081 | Zimices                                                                                                                                                     |
| 201 |     35.920644 |    340.903405 | Jagged Fang Designs                                                                                                                                         |
| 202 |    991.659537 |    468.714399 | FJDegrange                                                                                                                                                  |
| 203 |    759.558034 |    332.354647 | Birgit Lang                                                                                                                                                 |
| 204 |    576.113733 |    372.745395 | Matt Crook                                                                                                                                                  |
| 205 |    839.177736 |     52.028163 | Margot Michaud                                                                                                                                              |
| 206 |    888.119299 |    443.702273 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                               |
| 207 |   1011.165964 |    555.648741 | Maxime Dahirel                                                                                                                                              |
| 208 |    640.020558 |    270.672792 | Kamil S. Jaron                                                                                                                                              |
| 209 |    678.154082 |    533.148144 | Josefine Bohr Brask                                                                                                                                         |
| 210 |    227.772688 |    421.787531 | Ferran Sayol                                                                                                                                                |
| 211 |    477.949973 |    715.155895 | Gabriela Palomo-Munoz                                                                                                                                       |
| 212 |    270.665876 |    236.348087 | Steven Traver                                                                                                                                               |
| 213 |     54.721586 |     15.178712 | Yusan Yang                                                                                                                                                  |
| 214 |    746.541752 |    252.859840 | Zimices                                                                                                                                                     |
| 215 |    724.127210 |    740.387246 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                  |
| 216 |     40.647052 |    331.458829 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                               |
| 217 |    195.851200 |    719.104679 | Zimices                                                                                                                                                     |
| 218 |    548.231994 |    705.610390 | Zimices                                                                                                                                                     |
| 219 |    696.711641 |    544.221342 | Matt Crook                                                                                                                                                  |
| 220 |    944.503651 |    617.736767 | Gareth Monger                                                                                                                                               |
| 221 |    759.110900 |    107.009096 | Manabu Bessho-Uehara                                                                                                                                        |
| 222 |    264.130279 |    711.109510 | CNZdenek                                                                                                                                                    |
| 223 |    113.170744 |    202.940690 | Gareth Monger                                                                                                                                               |
| 224 |    637.843269 |     50.287574 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                          |
| 225 |    452.369614 |    780.625566 | Matt Crook                                                                                                                                                  |
| 226 |    737.123736 |    320.487350 | Stacy Spensley (Modified)                                                                                                                                   |
| 227 |     27.824579 |     75.397350 | Brockhaus and Efron                                                                                                                                         |
| 228 |    145.869915 |    568.013071 | Christoph Schomburg                                                                                                                                         |
| 229 |    651.218942 |    579.897533 | Gareth Monger                                                                                                                                               |
| 230 |    411.419114 |    132.317223 | Scott Hartman                                                                                                                                               |
| 231 |    277.769237 |    652.778857 | Ferran Sayol                                                                                                                                                |
| 232 |    428.631998 |    773.166079 | NA                                                                                                                                                          |
| 233 |    385.842117 |    184.621045 | Matt Crook                                                                                                                                                  |
| 234 |     56.254907 |    299.077205 | Matt Crook                                                                                                                                                  |
| 235 |     91.135404 |     44.504514 | Sarah Werning                                                                                                                                               |
| 236 |   1005.691609 |    134.061392 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                               |
| 237 |    587.144835 |    448.291579 | Gareth Monger                                                                                                                                               |
| 238 |    738.238883 |    280.570263 | Sarah Werning                                                                                                                                               |
| 239 |    433.183341 |    197.923864 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                    |
| 240 |    931.500047 |    300.984198 | Ieuan Jones                                                                                                                                                 |
| 241 |    846.492214 |    574.096999 | Renata F. Martins                                                                                                                                           |
| 242 |    338.180831 |    161.617439 | Davidson Sodré                                                                                                                                              |
| 243 |    766.528351 |    422.180227 | Renata F. Martins                                                                                                                                           |
| 244 |    925.235984 |    612.324483 | Joanna Wolfe                                                                                                                                                |
| 245 |    507.796951 |    195.423133 | Jagged Fang Designs                                                                                                                                         |
| 246 |    653.071226 |    235.797424 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                            |
| 247 |      5.625812 |    348.835846 | Dean Schnabel                                                                                                                                               |
| 248 |    556.417640 |    174.982853 | Matt Crook                                                                                                                                                  |
| 249 |    943.146519 |    792.347513 | Matt Crook                                                                                                                                                  |
| 250 |    787.560241 |    520.736942 | Ferran Sayol                                                                                                                                                |
| 251 |     63.062406 |    279.516695 | Matt Crook                                                                                                                                                  |
| 252 |    267.705749 |     47.463006 | Matt Crook                                                                                                                                                  |
| 253 |    145.265892 |     32.937562 | Falconaumanni and T. Michael Keesey                                                                                                                         |
| 254 |     91.898489 |    792.707638 | NA                                                                                                                                                          |
| 255 |    696.265002 |    269.444256 | Dean Schnabel                                                                                                                                               |
| 256 |    478.732251 |     20.066887 | Tomas Willems (vectorized by T. Michael Keesey)                                                                                                             |
| 257 |     98.942753 |    335.725945 | Emily Willoughby                                                                                                                                            |
| 258 |    196.453609 |    395.779847 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 259 |    356.046010 |    298.489187 | Maija Karala                                                                                                                                                |
| 260 |    421.094513 |    602.417813 | Zimices                                                                                                                                                     |
| 261 |    108.113018 |    294.464799 | Matt Crook                                                                                                                                                  |
| 262 |    683.146404 |     51.764891 | Gareth Monger                                                                                                                                               |
| 263 |    769.314564 |    762.968085 | NA                                                                                                                                                          |
| 264 |    574.045025 |    580.044327 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                           |
| 265 |    187.244647 |    428.709401 | Ingo Braasch                                                                                                                                                |
| 266 |   1000.262584 |    176.515219 | Margot Michaud                                                                                                                                              |
| 267 |    551.099565 |    108.599992 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 268 |    520.948924 |     49.048272 | Matt Martyniuk                                                                                                                                              |
| 269 |    901.914322 |    424.564061 | Zimices                                                                                                                                                     |
| 270 |    711.286660 |    319.640702 | T. Michael Keesey                                                                                                                                           |
| 271 |    104.894148 |    651.660129 | Jakovche                                                                                                                                                    |
| 272 |    572.682648 |    125.523774 | Zimices                                                                                                                                                     |
| 273 |     37.759516 |    636.476721 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                    |
| 274 |    982.177284 |    429.622582 | Scott Hartman                                                                                                                                               |
| 275 |    874.670027 |    432.471239 | Margot Michaud                                                                                                                                              |
| 276 |     79.331699 |     94.524502 | Rebecca Groom                                                                                                                                               |
| 277 |    217.160716 |    698.063082 | Cesar Julian                                                                                                                                                |
| 278 |    644.809503 |     82.580776 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                |
| 279 |    239.650705 |    411.423076 | Zimices                                                                                                                                                     |
| 280 |    134.984811 |    215.518173 | David Tana                                                                                                                                                  |
| 281 |    833.187891 |     91.354445 | Matt Crook                                                                                                                                                  |
| 282 |    733.539046 |     23.941929 | Yan Wong                                                                                                                                                    |
| 283 |    700.848363 |    283.939169 | Dave Angelini                                                                                                                                               |
| 284 |    744.625723 |    386.726373 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                 |
| 285 |    905.000006 |    624.874013 | Ferran Sayol                                                                                                                                                |
| 286 |    994.774253 |    131.218108 | Mason McNair                                                                                                                                                |
| 287 |    360.699030 |    727.764741 | Gareth Monger                                                                                                                                               |
| 288 |    146.446640 |    342.331581 | Zimices                                                                                                                                                     |
| 289 |    772.155109 |    402.387437 | Roberto Díaz Sibaja                                                                                                                                         |
| 290 |      9.631214 |    332.206192 | Sarah Werning                                                                                                                                               |
| 291 |    159.465220 |    325.661743 | T. Michael Keesey                                                                                                                                           |
| 292 |   1000.480907 |    713.574179 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                              |
| 293 |    197.355767 |    602.173155 | Beth Reinke                                                                                                                                                 |
| 294 |      8.065534 |    142.005755 | Gabriela Palomo-Munoz                                                                                                                                       |
| 295 |    141.827901 |    114.676641 | David Orr                                                                                                                                                   |
| 296 |    770.848905 |    163.075947 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                 |
| 297 |    890.829171 |    180.328368 |                                                                                                                                                             |
| 298 |    571.807014 |    641.260605 | Margot Michaud                                                                                                                                              |
| 299 |    975.063078 |     11.722304 | Jose Carlos Arenas-Monroy                                                                                                                                   |
| 300 |    892.599903 |    698.881253 | Steven Coombs                                                                                                                                               |
| 301 |    189.790191 |    709.267602 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                             |
| 302 |   1007.336343 |     55.376950 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                         |
| 303 |    647.193095 |    629.661548 | Margot Michaud                                                                                                                                              |
| 304 |    286.998364 |     10.687746 | Sarah Werning                                                                                                                                               |
| 305 |     29.685341 |    721.279281 | NA                                                                                                                                                          |
| 306 |    424.711345 |    704.812105 | Jonathan Wells                                                                                                                                              |
| 307 |    682.733149 |    590.836520 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                  |
| 308 |     13.338368 |    569.693607 | Birgit Lang                                                                                                                                                 |
| 309 |    288.360641 |    676.306612 | Yan Wong                                                                                                                                                    |
| 310 |    951.444295 |    481.330120 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                               |
| 311 |    672.434090 |    210.871326 | Benchill                                                                                                                                                    |
| 312 |    852.159091 |    479.020030 | Iain Reid                                                                                                                                                   |
| 313 |    540.634610 |    682.394432 | Jonathan Wells                                                                                                                                              |
| 314 |    277.143479 |     66.824124 | Alexander Schmidt-Lebuhn                                                                                                                                    |
| 315 |    166.791961 |    760.346618 | Jaime Headden                                                                                                                                               |
| 316 |    897.293948 |    224.252099 | \[unknown\]                                                                                                                                                 |
| 317 |    822.889196 |    498.488994 | Steven Traver                                                                                                                                               |
| 318 |    997.057780 |    649.657860 | Pedro de Siracusa                                                                                                                                           |
| 319 |    263.295372 |    720.088168 | Zimices                                                                                                                                                     |
| 320 |    936.301933 |    514.381584 | Joanna Wolfe                                                                                                                                                |
| 321 |     75.538364 |    290.281653 | Todd Marshall, vectorized by Zimices                                                                                                                        |
| 322 |    975.888413 |    298.869257 | Katie S. Collins                                                                                                                                            |
| 323 |    733.047546 |    374.792802 | Steven Traver                                                                                                                                               |
| 324 |    749.111322 |    447.121453 | Nobu Tamura                                                                                                                                                 |
| 325 |   1010.353058 |    615.322085 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                |
| 326 |    324.119703 |     66.811930 | Milton Tan                                                                                                                                                  |
| 327 |    936.475857 |    543.106124 | Gareth Monger                                                                                                                                               |
| 328 |    646.242699 |    658.239699 | Matt Crook                                                                                                                                                  |
| 329 |     43.887686 |    455.205989 | Gareth Monger                                                                                                                                               |
| 330 |    970.640676 |    361.270294 | Jagged Fang Designs                                                                                                                                         |
| 331 |   1011.451972 |    720.125460 | Tim H. Heupink, Leon Huynen, and David M. Lambert (vectorized by T. Michael Keesey)                                                                         |
| 332 |     27.243787 |    787.120483 | Yan Wong                                                                                                                                                    |
| 333 |    994.140630 |    224.565112 | Joanna Wolfe                                                                                                                                                |
| 334 |    167.852014 |     70.832230 | Sarah Werning                                                                                                                                               |
| 335 |    407.522005 |    789.708276 | Ferran Sayol                                                                                                                                                |
| 336 |    935.975660 |    200.580864 | Yan Wong                                                                                                                                                    |
| 337 |    632.369561 |    629.938328 | Kamil S. Jaron                                                                                                                                              |
| 338 |    723.974711 |    611.526893 | Matt Crook                                                                                                                                                  |
| 339 |     14.317224 |    751.022311 | Kamil S. Jaron                                                                                                                                              |
| 340 |    678.185344 |    647.887567 | Margot Michaud                                                                                                                                              |
| 341 |     35.472221 |    319.718186 | Jagged Fang Designs                                                                                                                                         |
| 342 |     81.463290 |    260.189537 | Ferran Sayol                                                                                                                                                |
| 343 |     29.279206 |    585.320386 | Matt Crook                                                                                                                                                  |
| 344 |    872.234829 |    361.941107 | Beth Reinke                                                                                                                                                 |
| 345 |    184.874393 |    141.955204 | Maija Karala                                                                                                                                                |
| 346 |     35.716312 |     91.975936 | Gabriela Palomo-Munoz                                                                                                                                       |
| 347 |    349.801749 |    381.086349 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                               |
| 348 |    351.838551 |     79.142741 | Yan Wong                                                                                                                                                    |
| 349 |    520.448476 |     78.800718 | Steven Traver                                                                                                                                               |
| 350 |     20.039800 |    635.001990 | Scott Hartman                                                                                                                                               |
| 351 |    443.700139 |     29.815373 | Karla Martinez                                                                                                                                              |
| 352 |    365.953368 |    333.124958 | Chris huh                                                                                                                                                   |
| 353 |    599.134450 |    553.911502 | Matt Crook                                                                                                                                                  |
| 354 |    376.915747 |    385.533156 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                         |
| 355 |    680.424595 |    550.594478 | Margot Michaud                                                                                                                                              |
| 356 |    820.729586 |    792.131142 | NA                                                                                                                                                          |
| 357 |    713.155965 |    276.147285 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                       |
| 358 |     43.218795 |    674.055436 | Gabriela Palomo-Munoz                                                                                                                                       |
| 359 |    383.924029 |    178.225797 | Ferran Sayol                                                                                                                                                |
| 360 |   1001.721323 |    385.814230 | Harold N Eyster                                                                                                                                             |
| 361 |    151.155597 |    554.597976 | Scott Hartman                                                                                                                                               |
| 362 |     15.000274 |    492.449333 | Steven Traver                                                                                                                                               |
| 363 |    263.796256 |    618.113591 | (after Spotila 2004)                                                                                                                                        |
| 364 |    908.120539 |    322.749339 | Katie S. Collins                                                                                                                                            |
| 365 |    988.402835 |    589.680598 | Chris huh                                                                                                                                                   |
| 366 |    611.347815 |    235.030466 | Scott Hartman                                                                                                                                               |
| 367 |   1003.627319 |    451.673541 | Zimices                                                                                                                                                     |
| 368 |   1013.193439 |    120.034063 | Zimices                                                                                                                                                     |
| 369 |    845.897635 |    168.257972 | Melissa Broussard                                                                                                                                           |
| 370 |    820.664166 |    553.133448 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                           |
| 371 |    230.434002 |    135.828271 | Zimices                                                                                                                                                     |
| 372 |    520.788834 |    224.870314 | Matt Crook                                                                                                                                                  |
| 373 |    145.070239 |    671.155989 | Scott Hartman                                                                                                                                               |
| 374 |    890.712293 |     97.584762 | Michelle Site                                                                                                                                               |
| 375 |    576.344466 |    738.147724 | Zimices                                                                                                                                                     |
| 376 |    292.293799 |     86.497199 | Alex Slavenko                                                                                                                                               |
| 377 |    814.561286 |    621.876369 | Luis Cunha                                                                                                                                                  |
| 378 |    607.328948 |    450.629615 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                           |
| 379 |    258.790116 |    137.413108 | Scott Hartman                                                                                                                                               |
| 380 |    293.844207 |     99.013600 | Matt Dempsey                                                                                                                                                |
| 381 |    322.534988 |    229.686670 | Steven Traver                                                                                                                                               |
| 382 |     21.242365 |    609.798407 | Zimices                                                                                                                                                     |
| 383 |    550.148969 |    790.089371 | M Kolmann                                                                                                                                                   |
| 384 |    681.308314 |    345.304806 | NA                                                                                                                                                          |
| 385 |    516.603453 |    202.306810 | Matt Crook                                                                                                                                                  |
| 386 |    896.295787 |    283.758045 | Maija Karala                                                                                                                                                |
| 387 |    607.166060 |    573.138677 | C. Camilo Julián-Caballero                                                                                                                                  |
| 388 |    690.781685 |    700.326418 | Matt Crook                                                                                                                                                  |
| 389 |   1016.102636 |    303.761332 | T. Michael Keesey                                                                                                                                           |
| 390 |    483.530905 |    175.232328 | Emily Willoughby                                                                                                                                            |
| 391 |    451.719193 |    765.748701 | Tasman Dixon                                                                                                                                                |
| 392 |    346.379724 |    410.722444 | Jay Matternes, vectorized by Zimices                                                                                                                        |
| 393 |    707.659697 |    200.928764 | Mattia Menchetti                                                                                                                                            |
| 394 |    156.055009 |     92.315794 | Michael Scroggie                                                                                                                                            |
| 395 |    818.676647 |    481.674660 | Lukasiniho                                                                                                                                                  |
| 396 |     68.515113 |     61.783061 | Steven Traver                                                                                                                                               |
| 397 |     11.470619 |     77.822007 | Berivan Temiz                                                                                                                                               |
| 398 |    652.517779 |    716.776970 | Meliponicultor Itaymbere                                                                                                                                    |
| 399 |    987.167879 |    353.351846 | Jay Matternes, vectorized by Zimices                                                                                                                        |
| 400 |    768.776182 |     12.704159 | Matt Crook                                                                                                                                                  |
| 401 |    746.511029 |    138.061661 | Francisco Manuel Blanco (vectorized by T. Michael Keesey)                                                                                                   |
| 402 |    852.542972 |    263.832665 | Ferran Sayol                                                                                                                                                |
| 403 |    258.869074 |    702.020728 | Neil Kelley                                                                                                                                                 |
| 404 |    187.092499 |    315.279761 | Kamil S. Jaron                                                                                                                                              |
| 405 |    314.687415 |     40.711420 | Gareth Monger                                                                                                                                               |
| 406 |   1005.978351 |    592.607744 | Gareth Monger                                                                                                                                               |
| 407 |     99.119924 |    578.081435 | Margot Michaud                                                                                                                                              |
| 408 |    337.040469 |     95.579239 | Margot Michaud                                                                                                                                              |
| 409 |    335.842298 |      9.833151 | Noah Schlottman, photo from Casey Dunn                                                                                                                      |
| 410 |    830.879382 |    149.987420 | Jaime Headden                                                                                                                                               |
| 411 |    429.563276 |      6.778542 | Chris huh                                                                                                                                                   |
| 412 |    843.001176 |    645.653527 | Gareth Monger                                                                                                                                               |
| 413 |    302.541245 |     76.132707 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey  |
| 414 |    154.460473 |     23.954380 | Matt Crook                                                                                                                                                  |
| 415 |    686.053511 |    472.229346 | NA                                                                                                                                                          |
| 416 |    700.325541 |      4.979843 | Tasman Dixon                                                                                                                                                |
| 417 |    343.399917 |    424.875040 | Matt Wilkins                                                                                                                                                |
| 418 |    347.833537 |    562.007364 | Qiang Ou                                                                                                                                                    |
| 419 |    643.177203 |    113.255649 | Chris huh                                                                                                                                                   |
| 420 |    574.219663 |    558.782920 | Crystal Maier                                                                                                                                               |
| 421 |     98.261926 |     23.213857 | Tasman Dixon                                                                                                                                                |
| 422 |    564.955993 |    395.534627 | Matt Crook                                                                                                                                                  |
| 423 |    990.419177 |    316.336330 | Sarah Werning                                                                                                                                               |
| 424 |    767.070726 |    485.486566 | Gustav Mützel                                                                                                                                               |
| 425 |    553.887182 |    566.536275 | Margot Michaud                                                                                                                                              |
| 426 |    683.817490 |    440.887586 | Zimices                                                                                                                                                     |
| 427 |   1011.690482 |    780.770775 | L. Shyamal                                                                                                                                                  |
| 428 |    957.078451 |    119.698219 | Gareth Monger                                                                                                                                               |
| 429 |    979.637930 |     34.608793 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                       |
| 430 |    467.390083 |    734.301077 | Andrew A. Farke                                                                                                                                             |
| 431 |    450.553662 |    660.559171 | Scott Hartman                                                                                                                                               |
| 432 |    827.408618 |    648.411687 | Mali’o Kodis, photograph by Ching (<http://www.flickr.com/photos/36302473@N03/>)                                                                            |
| 433 |    964.292976 |    315.327312 | Jaime Headden                                                                                                                                               |
| 434 |    847.387303 |    612.057160 | Emily Willoughby                                                                                                                                            |
| 435 |    733.364346 |    495.501812 | Steven Traver                                                                                                                                               |
| 436 |    567.384342 |    414.836169 | FunkMonk                                                                                                                                                    |
| 437 |   1009.739775 |    392.244001 | Matt Crook                                                                                                                                                  |
| 438 |    349.330363 |    164.702300 | Margot Michaud                                                                                                                                              |
| 439 |    871.943441 |    330.133210 | Taenadoman                                                                                                                                                  |
| 440 |    545.335947 |    478.607610 | Kanako Bessho-Uehara                                                                                                                                        |
| 441 |    994.724561 |    425.925426 | Zimices                                                                                                                                                     |
| 442 |    992.331007 |    736.898357 | T. Michael Keesey                                                                                                                                           |
| 443 |    872.036143 |     56.328961 | Burton Robert, USFWS                                                                                                                                        |
| 444 |    817.572094 |    778.552528 | Margot Michaud                                                                                                                                              |
| 445 |    946.632997 |    609.575021 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 446 |    254.487687 |    244.344916 | Beth Reinke                                                                                                                                                 |
| 447 |    946.371979 |    627.508181 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                               |
| 448 |    845.821982 |     77.004242 | Mariana Ruiz Villarreal                                                                                                                                     |
| 449 |    766.567763 |    247.931531 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                 |
| 450 |    986.004139 |     53.557837 | NA                                                                                                                                                          |
| 451 |    375.883825 |    499.578972 | Martin R. Smith                                                                                                                                             |
| 452 |    238.457216 |    646.718520 | Anthony Caravaggi                                                                                                                                           |
| 453 |    711.340968 |    259.087911 | Steven Coombs (vectorized by T. Michael Keesey)                                                                                                             |
| 454 |    225.003215 |    746.163936 | Margot Michaud                                                                                                                                              |
| 455 |    844.034042 |    626.767743 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                              |
| 456 |    740.596016 |     83.017874 | Tasman Dixon                                                                                                                                                |
| 457 |    964.174695 |    389.012819 | NA                                                                                                                                                          |
| 458 |    637.200724 |    257.801750 | Matt Crook                                                                                                                                                  |
| 459 |    776.728628 |    547.101263 | Armelle Ansart (photograph), Maxime Dahirel (digitisation)                                                                                                  |
| 460 |   1015.893398 |    240.756102 | Collin Gross                                                                                                                                                |
| 461 |    147.765613 |    612.038651 | Pete Buchholz                                                                                                                                               |
| 462 |    110.114889 |    340.062885 | Jaime Headden                                                                                                                                               |
| 463 |    619.158893 |     47.764426 | Michael Scroggie                                                                                                                                            |
| 464 |    496.985140 |    105.593357 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                               |
| 465 |    251.504708 |     77.764765 | Sarah Werning                                                                                                                                               |
| 466 |    776.911004 |    466.969709 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                               |
| 467 |    343.401306 |    257.123910 | Matt Crook                                                                                                                                                  |
| 468 |    115.635832 |      9.731865 | Zimices                                                                                                                                                     |
| 469 |    433.577798 |    482.866819 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 470 |     50.662874 |    447.401359 | Mathieu Basille                                                                                                                                             |
| 471 |    476.114253 |    269.776202 | Ferran Sayol                                                                                                                                                |
| 472 |    525.964307 |     91.438563 | Noah Schlottman, photo from Casey Dunn                                                                                                                      |
| 473 |    431.768791 |    472.037274 | Joanna Wolfe                                                                                                                                                |
| 474 |      7.279871 |    706.939017 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                        |
| 475 |    699.931748 |    556.068878 | Emily Willoughby                                                                                                                                            |
| 476 |    436.520386 |    353.804098 | Matt Crook                                                                                                                                                  |
| 477 |    172.779616 |    778.063281 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                    |
| 478 |    149.306960 |    778.863786 | NA                                                                                                                                                          |
| 479 |     95.409100 |     31.542774 | NA                                                                                                                                                          |
| 480 |    814.885644 |    736.888081 | Birgit Lang                                                                                                                                                 |
| 481 |    980.691735 |    780.912993 | Andrew A. Farke                                                                                                                                             |
| 482 |    807.585525 |     96.500125 | Matt Crook                                                                                                                                                  |
| 483 |    980.273387 |    611.217437 | Matt Crook                                                                                                                                                  |
| 484 |    978.515914 |    195.717124 | Fernando Carezzano                                                                                                                                          |
| 485 |    131.217212 |    588.207977 | Mali’o Kodis, photograph from <http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>                                                                       |
| 486 |    955.515149 |    497.083531 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                         |
| 487 |    921.486162 |    205.279607 | Harold N Eyster                                                                                                                                             |
| 488 |    551.540225 |     48.788381 | Ludwik Gasiorowski                                                                                                                                          |
| 489 |    383.930034 |    266.345327 | Steven Traver                                                                                                                                               |
| 490 |    159.161534 |    601.088352 | Margot Michaud                                                                                                                                              |
| 491 |    698.661759 |    485.887253 | Matt Hayes                                                                                                                                                  |
| 492 |    726.378756 |    541.441554 | Tracy A. Heath                                                                                                                                              |
| 493 |    751.364272 |    259.667484 | Scott Hartman                                                                                                                                               |
| 494 |    966.020984 |    600.971375 | Yan Wong                                                                                                                                                    |
| 495 |    512.900839 |    793.091043 | Jon M Laurent                                                                                                                                               |
| 496 |    514.422294 |    509.626889 | Margot Michaud                                                                                                                                              |
| 497 |    924.757206 |    194.268818 | Dmitry Bogdanov                                                                                                                                             |
| 498 |    439.935024 |    649.851444 | Matt Crook                                                                                                                                                  |
| 499 |    855.506402 |    138.116820 | Zimices                                                                                                                                                     |
| 500 |     78.053460 |    769.397800 | G. M. Woodward                                                                                                                                              |
| 501 |    959.748725 |    552.404594 | Tracy A. Heath                                                                                                                                              |
| 502 |    331.364656 |    700.589827 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                |
| 503 |    635.782121 |    222.802890 | Gareth Monger                                                                                                                                               |
| 504 |    167.668198 |    313.263052 | Jonathan Lawley                                                                                                                                             |
| 505 |    596.240022 |    255.423240 | NA                                                                                                                                                          |
| 506 |    524.806343 |    356.052453 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 507 |    463.902715 |    544.229278 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 508 |    773.457955 |    136.576089 | Jagged Fang Designs                                                                                                                                         |
| 509 |    637.677784 |    162.874780 | Zimices                                                                                                                                                     |
| 510 |    254.985928 |    637.330273 | Gareth Monger                                                                                                                                               |
| 511 |   1007.465607 |      8.447245 | Smokeybjb                                                                                                                                                   |
| 512 |    207.787723 |    625.373686 | Pedro de Siracusa                                                                                                                                           |
| 513 |    336.648714 |    718.230714 | Gabriela Palomo-Munoz                                                                                                                                       |
| 514 |    954.447936 |    192.503797 | T. Michael Keesey                                                                                                                                           |
| 515 |    307.070723 |    277.026025 | Steven Traver                                                                                                                                               |
| 516 |    437.173945 |    523.900536 | Yan Wong                                                                                                                                                    |
| 517 |    185.613422 |    790.605211 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                             |
| 518 |    615.752153 |    108.115835 | NA                                                                                                                                                          |
| 519 |   1006.632701 |    439.171785 | Felix Vaux                                                                                                                                                  |
| 520 |   1012.235997 |    476.218371 | Michelle Site                                                                                                                                               |
| 521 |    221.909587 |    159.683069 | Alexander Schmidt-Lebuhn                                                                                                                                    |
| 522 |     71.173326 |     48.065165 | Andrew A. Farke                                                                                                                                             |
| 523 |    950.318646 |     12.112090 | NA                                                                                                                                                          |
| 524 |    968.204874 |    665.218746 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                 |
| 525 |    572.039853 |    262.075315 | Steven Traver                                                                                                                                               |
| 526 |    991.557972 |    241.673528 | Steven Haddock • Jellywatch.org                                                                                                                             |
| 527 |    321.749352 |    559.512726 | Zimices                                                                                                                                                     |
| 528 |    637.756400 |     98.138952 | Matt Crook                                                                                                                                                  |
| 529 |    792.866685 |    537.640192 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                           |
| 530 |    652.675261 |    262.544122 | Jagged Fang Designs                                                                                                                                         |
| 531 |    184.544587 |    419.046305 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                             |
| 532 |    633.854356 |    610.076720 | T. Michael Keesey                                                                                                                                           |
| 533 |    396.723122 |    343.792792 | Matt Martyniuk                                                                                                                                              |
| 534 |    983.372014 |    791.613746 | Margot Michaud                                                                                                                                              |
| 535 |    635.930402 |    373.433302 | NA                                                                                                                                                          |
| 536 |     28.060132 |    545.942752 | Shyamal                                                                                                                                                     |
| 537 |    247.124876 |    785.063637 | Mathieu Basille                                                                                                                                             |
| 538 |    666.526819 |    455.664263 | Chris huh                                                                                                                                                   |
| 539 |    517.656689 |    652.601528 | Christian A. Masnaghetti                                                                                                                                    |
| 540 |    369.534890 |    580.964133 | Scott Hartman                                                                                                                                               |
| 541 |    894.428487 |    747.992964 | Zimices                                                                                                                                                     |
| 542 |    856.172213 |    559.043145 | Noah Schlottman, photo by Carlos Sánchez-Ortiz                                                                                                              |
| 543 |     46.489634 |    308.351231 | Scott Hartman                                                                                                                                               |
| 544 |    386.371785 |    697.964578 | NA                                                                                                                                                          |
| 545 |    286.400755 |     26.500061 | S.Martini                                                                                                                                                   |
| 546 |    731.514425 |    759.038867 | Steven Traver                                                                                                                                               |
| 547 |    749.189476 |    594.854678 | Smokeybjb                                                                                                                                                   |
| 548 |    408.926929 |    659.360888 | T. Michael Keesey                                                                                                                                           |
| 549 |    691.561782 |    198.229179 | Chris Jennings (Risiatto)                                                                                                                                   |
| 550 |      6.341115 |    412.267727 | Roger Witter, vectorized by Zimices                                                                                                                         |
| 551 |    198.645279 |    344.887185 | Mason McNair                                                                                                                                                |
| 552 |    305.185640 |    599.599719 | H. Filhol (vectorized by T. Michael Keesey)                                                                                                                 |
| 553 |    875.822779 |    480.127832 | Griensteidl and T. Michael Keesey                                                                                                                           |
| 554 |     56.894624 |    720.547953 | Plukenet                                                                                                                                                    |
| 555 |    438.452425 |    718.094621 | Matt Crook                                                                                                                                                  |
| 556 |    290.352010 |    154.810186 | Gareth Monger                                                                                                                                               |
| 557 |    784.130561 |    264.507405 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                           |
| 558 |      6.853017 |    110.852232 | Crystal Maier                                                                                                                                               |
| 559 |    997.241628 |     66.228296 | NA                                                                                                                                                          |
| 560 |    333.607670 |    410.537289 | Meliponicultor Itaymbere                                                                                                                                    |
| 561 |    453.593354 |    559.237877 | Kamil S. Jaron                                                                                                                                              |
| 562 |    579.675754 |    724.562415 | Ricardo Araújo                                                                                                                                              |
| 563 |    589.858672 |      7.065595 | Gareth Monger                                                                                                                                               |
| 564 |    214.218142 |    541.656925 | M Kolmann                                                                                                                                                   |
| 565 |    704.504637 |    398.803091 | Zimices                                                                                                                                                     |
| 566 |    622.820207 |    285.853156 | T. Michael Keesey                                                                                                                                           |
| 567 |    967.363628 |    375.464769 | Steven Traver                                                                                                                                               |
| 568 |    478.775829 |     93.553279 | Margot Michaud                                                                                                                                              |
| 569 |     81.766205 |    145.356605 | Steven Traver                                                                                                                                               |
| 570 |    648.581295 |    198.505792 | Gareth Monger                                                                                                                                               |
| 571 |    434.956992 |    370.961376 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                     |
| 572 |    218.795285 |    549.423168 | NA                                                                                                                                                          |
| 573 |    346.475268 |    709.934331 | Birgit Lang                                                                                                                                                 |
| 574 |    117.505542 |    223.768892 | NA                                                                                                                                                          |
| 575 |     23.430222 |     76.439399 | NA                                                                                                                                                          |
| 576 |    852.631545 |    510.909110 | Iain Reid                                                                                                                                                   |
| 577 |     24.393718 |    538.616299 | Cesar Julian                                                                                                                                                |
| 578 |    761.174014 |    373.601086 | Neil Kelley                                                                                                                                                 |
| 579 |    560.486027 |    558.555824 | T. Michael Keesey                                                                                                                                           |
| 580 |    376.220357 |    148.116208 | Cesar Julian                                                                                                                                                |
| 581 |   1007.643816 |    688.422820 | Scott Hartman                                                                                                                                               |
| 582 |    980.119429 |    382.180968 | L. Shyamal                                                                                                                                                  |
| 583 |    415.916115 |    452.146545 | Steven Traver                                                                                                                                               |
| 584 |    865.429505 |    351.296944 | Scott Hartman                                                                                                                                               |
| 585 |    362.693769 |    403.323223 | Christoph Schomburg                                                                                                                                         |
| 586 |    428.071056 |    384.834113 | Gabriela Palomo-Munoz                                                                                                                                       |
| 587 |     98.020877 |    208.188581 | Sarah Werning                                                                                                                                               |
| 588 |    133.723566 |    149.466563 | Mathilde Cordellier                                                                                                                                         |
| 589 |    604.816918 |    148.316261 | David Orr                                                                                                                                                   |
| 590 |    940.265710 |    694.784938 | Gabriela Palomo-Munoz                                                                                                                                       |
| 591 |    425.133888 |    461.553568 | Qiang Ou                                                                                                                                                    |
| 592 |    794.504081 |    252.176101 | Andrew A. Farke                                                                                                                                             |
| 593 |    911.196359 |    417.902840 | Tracy A. Heath                                                                                                                                              |
| 594 |    900.339899 |    311.962310 | Tasman Dixon                                                                                                                                                |
| 595 |    883.185050 |    566.861174 | Sarah Werning                                                                                                                                               |
| 596 |    472.961271 |    383.976260 | Matt Crook                                                                                                                                                  |
| 597 |    427.884402 |     33.175858 | Melissa Broussard                                                                                                                                           |
| 598 |    336.419211 |     58.364375 | NA                                                                                                                                                          |
| 599 |     16.721296 |    350.970808 | Matt Crook                                                                                                                                                  |
| 600 |    785.313912 |    175.130770 | Jessica Anne Miller                                                                                                                                         |
| 601 |    207.925746 |    135.958308 | Zimices                                                                                                                                                     |
| 602 |    473.378384 |    579.206377 | Matt Martyniuk                                                                                                                                              |
| 603 |    832.319979 |    256.636719 | Alex Slavenko                                                                                                                                               |
| 604 |    250.760486 |    404.268088 | Beth Reinke                                                                                                                                                 |
| 605 |    640.182523 |     10.437540 | . Original drawing by M. Antón, published in Montoya and Morales 1984. Vectorized by O. Sanisidro                                                           |
| 606 |    300.500524 |     37.890492 | Matt Crook                                                                                                                                                  |
| 607 |   1002.551945 |    775.579696 | Steven Haddock • Jellywatch.org                                                                                                                             |
| 608 |    262.346703 |    307.281578 | Fcb981 (vectorized by T. Michael Keesey)                                                                                                                    |
| 609 |    112.617625 |    791.066200 | Tyler Greenfield                                                                                                                                            |
| 610 |    218.974424 |    106.530406 | Benjamint444                                                                                                                                                |
| 611 |    474.231476 |    658.661615 | Ferran Sayol                                                                                                                                                |
| 612 |    397.688408 |    603.154726 | NA                                                                                                                                                          |
| 613 |    887.516966 |    462.303784 | Ferran Sayol                                                                                                                                                |
| 614 |     40.293887 |    757.962284 | Gareth Monger                                                                                                                                               |
| 615 |    515.918271 |     19.401581 | Gareth Monger                                                                                                                                               |
| 616 |    229.596551 |    104.678891 | Felix Vaux                                                                                                                                                  |
| 617 |    261.243002 |    436.887532 | Gareth Monger                                                                                                                                               |
| 618 |    748.523047 |    561.506749 | Scott Hartman                                                                                                                                               |
| 619 |    843.301615 |    559.105876 | Harold N Eyster                                                                                                                                             |
| 620 |    366.249532 |    255.077716 | Matt Crook                                                                                                                                                  |
| 621 |    284.805999 |    691.777339 | Collin Gross                                                                                                                                                |
| 622 |    411.568853 |    617.035248 | Inessa Voet                                                                                                                                                 |
| 623 |    387.598102 |    276.223224 | Chris huh                                                                                                                                                   |
| 624 |    768.903766 |     33.274819 | NA                                                                                                                                                          |
| 625 |    454.896255 |    386.390930 | Matt Crook                                                                                                                                                  |
| 626 |    527.300064 |    282.784705 | Zimices                                                                                                                                                     |
| 627 |    530.753775 |     67.200530 | Yan Wong                                                                                                                                                    |
| 628 |   1015.987974 |    607.172481 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                              |
| 629 |     27.726010 |    182.968028 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                               |
| 630 |     64.415340 |    734.192364 | Crystal Maier                                                                                                                                               |
| 631 |    670.337674 |    677.776620 | Ryan Cupo                                                                                                                                                   |
| 632 |    996.332016 |    155.386172 | Ferran Sayol                                                                                                                                                |
| 633 |    751.984762 |    283.696568 | S.Martini                                                                                                                                                   |
| 634 |    419.666080 |     17.522716 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                           |
| 635 |    659.878536 |     88.266745 | Richard Parker (vectorized by T. Michael Keesey)                                                                                                            |
| 636 |   1013.510397 |    147.081258 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                           |
| 637 |    842.855080 |    104.406390 | Jagged Fang Designs                                                                                                                                         |
| 638 |    807.311683 |    475.573240 | T. Michael Keesey                                                                                                                                           |
| 639 |    848.564909 |    489.877042 | Steven Traver                                                                                                                                               |
| 640 |    810.471558 |    544.104678 | Metalhead64 (vectorized by T. Michael Keesey)                                                                                                               |
| 641 |    629.582247 |     39.914010 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                              |
| 642 |    980.788960 |    750.805663 | Yan Wong from illustration by Jules Richard (1907)                                                                                                          |
| 643 |    924.364971 |    318.546286 | Steven Traver                                                                                                                                               |
| 644 |    654.743686 |    745.664588 | Gabriela Palomo-Munoz                                                                                                                                       |
| 645 |    519.279200 |    532.349645 | Matt Martyniuk                                                                                                                                              |
| 646 |    368.199032 |    714.272506 | Nicolas Mongiardino Koch                                                                                                                                    |
| 647 |    954.437272 |    693.973246 | Sergio A. Muñoz-Gómez                                                                                                                                       |
| 648 |    856.180616 |    392.721945 | Rebecca Groom                                                                                                                                               |
| 649 |    401.392785 |    709.409218 | Matus Valach                                                                                                                                                |
| 650 |    640.840869 |     70.301380 | Zimices                                                                                                                                                     |
| 651 |     22.233418 |    438.636248 | T. Michael Keesey                                                                                                                                           |
| 652 |    352.071685 |    288.362874 | C. Camilo Julián-Caballero                                                                                                                                  |
| 653 |   1009.202231 |    218.683822 | Nobu Tamura, vectorized by Zimices                                                                                                                          |
| 654 |    931.511361 |    340.455586 | Ferran Sayol                                                                                                                                                |
| 655 |    655.714572 |    734.764299 | Maija Karala                                                                                                                                                |
| 656 |    363.725091 |     57.766901 | Zimices                                                                                                                                                     |
| 657 |     57.011221 |    332.664320 | Margot Michaud                                                                                                                                              |
| 658 |    414.232073 |    271.157560 | Margot Michaud                                                                                                                                              |
| 659 |    219.666316 |    400.265228 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                         |
| 660 |    351.186731 |    270.690613 | Katie S. Collins                                                                                                                                            |
| 661 |    110.199761 |    477.429956 | Zimices                                                                                                                                                     |
| 662 |    986.503718 |    482.998531 | Margot Michaud                                                                                                                                              |
| 663 |    541.083755 |    251.971916 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 664 |    972.590226 |    695.026960 | Matt Crook                                                                                                                                                  |
| 665 |    211.094025 |    417.952007 | Harold N Eyster                                                                                                                                             |
| 666 |    805.228914 |     73.038529 | Ferran Sayol                                                                                                                                                |
| 667 |    454.820788 |    586.077041 | Maxime Dahirel                                                                                                                                              |
| 668 |    302.934681 |    715.986555 | Gareth Monger                                                                                                                                               |
| 669 |    492.142770 |    116.885839 | Don Armstrong                                                                                                                                               |
| 670 |    731.740944 |      3.181274 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                             |
| 671 |    194.883295 |     15.172602 | Beth Reinke                                                                                                                                                 |
| 672 |    582.747643 |    137.737951 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                             |
| 673 |    534.293146 |    648.029773 | Gareth Monger                                                                                                                                               |
| 674 |    751.037118 |    236.600277 | Zimices                                                                                                                                                     |
| 675 |    253.957792 |    797.233114 | Yan Wong                                                                                                                                                    |
| 676 |    711.177155 |    750.084501 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                        |
| 677 |    864.154850 |    790.917868 | Chris huh                                                                                                                                                   |
| 678 |    533.947685 |    181.583509 | Kai R. Caspar                                                                                                                                               |
| 679 |     33.995362 |    738.478742 | Gareth Monger                                                                                                                                               |
| 680 |    289.052663 |    701.806176 | Scott Hartman                                                                                                                                               |
| 681 |    703.804269 |    371.576995 | T. Michael Keesey (after Colin M. L. Burnett)                                                                                                               |
| 682 |   1002.121124 |    104.564258 | Gareth Monger                                                                                                                                               |
| 683 |     22.645827 |    516.980400 | Zimices                                                                                                                                                     |
| 684 |    592.083728 |    402.429512 | Ferran Sayol                                                                                                                                                |
| 685 |    916.106935 |     58.759085 | H. Filhol (vectorized by T. Michael Keesey)                                                                                                                 |
| 686 |   1006.212027 |    513.910866 | Amanda Katzer                                                                                                                                               |
| 687 |    420.382658 |    633.587672 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                 |
| 688 |    552.427887 |     89.287745 | Michelle Site                                                                                                                                               |
| 689 |    634.665535 |    305.886547 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                     |
| 690 |    114.509870 |    576.688285 | FunkMonk                                                                                                                                                    |
| 691 |   1014.156826 |    159.841983 | NA                                                                                                                                                          |
| 692 |      8.676925 |    459.811262 | Chris huh                                                                                                                                                   |
| 693 |     86.638248 |    624.343405 | Chase Brownstein                                                                                                                                            |
| 694 |    330.936545 |    437.853393 | Steven Traver                                                                                                                                               |
| 695 |    498.540879 |    393.290538 | Ferran Sayol                                                                                                                                                |
| 696 |    747.102449 |    542.328275 | Gareth Monger                                                                                                                                               |
| 697 |    857.786106 |    640.783742 | Felix Vaux                                                                                                                                                  |
| 698 |    459.401340 |    282.024797 | Margot Michaud                                                                                                                                              |
| 699 |    359.530404 |    509.641217 | Matt Crook                                                                                                                                                  |
| 700 |    906.606983 |    282.976700 | Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 701 |   1003.304883 |     72.941332 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 702 |    305.077579 |     61.802613 | Matt Crook                                                                                                                                                  |
| 703 |    994.297453 |    565.646800 | Margot Michaud                                                                                                                                              |
| 704 |    704.816179 |    413.020804 | Steven Traver                                                                                                                                               |
| 705 |    352.118252 |    318.992404 | Darius Nau                                                                                                                                                  |
| 706 |    553.294262 |    291.914787 | Katie S. Collins                                                                                                                                            |
| 707 |    304.355522 |      9.951064 | Ferran Sayol                                                                                                                                                |
| 708 |    546.079747 |     72.409559 | NA                                                                                                                                                          |
| 709 |    283.857555 |    566.226827 | L. Shyamal                                                                                                                                                  |
| 710 |    983.277195 |    694.226274 | T. Michael Keesey                                                                                                                                           |
| 711 |     17.461312 |    175.322637 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                               |
| 712 |     47.741884 |    275.612207 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                             |
| 713 |    176.747221 |    209.759711 | Chris huh                                                                                                                                                   |
| 714 |    967.748922 |     41.267895 | Gareth Monger                                                                                                                                               |
| 715 |    308.484853 |    314.023880 | Steven Traver                                                                                                                                               |
| 716 |   1015.033571 |    177.999720 | Ferran Sayol                                                                                                                                                |
| 717 |      6.437610 |    198.537308 | Mark Hofstetter (vectorized by T. Michael Keesey)                                                                                                           |
| 718 |    786.643919 |     29.958237 | Gareth Monger                                                                                                                                               |
| 719 |    431.024661 |    784.419851 | Matt Crook                                                                                                                                                  |
| 720 |    889.007249 |    320.635237 | Sarah Werning                                                                                                                                               |
| 721 |    295.832879 |    337.854460 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                                        |
| 722 |    573.005837 |     11.525536 | Zimices                                                                                                                                                     |
| 723 |    682.576284 |    331.682506 | Sarah Werning                                                                                                                                               |
| 724 |    185.249697 |    399.822620 | FunkMonk                                                                                                                                                    |
| 725 |     97.827779 |    266.118939 | Mo Hassan                                                                                                                                                   |
| 726 |    789.411754 |    291.101576 | NA                                                                                                                                                          |
| 727 |   1003.246420 |    281.079586 | Beth Reinke                                                                                                                                                 |
| 728 |     13.940555 |    399.115804 | Milton Tan                                                                                                                                                  |
| 729 |    632.960411 |    667.852581 | Ingo Braasch                                                                                                                                                |
| 730 |    210.703675 |    346.216145 | NA                                                                                                                                                          |
| 731 |    318.546992 |    187.565915 | Ferran Sayol                                                                                                                                                |
| 732 |    652.412684 |     51.249263 | NA                                                                                                                                                          |
| 733 |    546.561151 |    121.450362 | Gareth Monger                                                                                                                                               |
| 734 |    291.824069 |     54.693905 | Chris huh                                                                                                                                                   |
| 735 |   1016.246337 |    365.542866 | Chris huh                                                                                                                                                   |
| 736 |    674.188316 |    264.159415 | Joanna Wolfe                                                                                                                                                |
| 737 |    492.381528 |    371.756312 | Margot Michaud                                                                                                                                              |
| 738 |    612.025369 |    424.864431 | Steven Coombs                                                                                                                                               |
| 739 |    565.740177 |    113.328993 | Gabriela Palomo-Munoz                                                                                                                                       |
| 740 |    722.521280 |    230.839014 | Collin Gross                                                                                                                                                |
| 741 |     53.627600 |    651.931485 | Margot Michaud                                                                                                                                              |
| 742 |    659.342764 |    192.983264 | T. Michael Keesey                                                                                                                                           |
| 743 |    667.283125 |     54.487894 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                |
| 744 |    154.188057 |    629.361504 | Margot Michaud                                                                                                                                              |
| 745 |      6.343545 |     33.874744 | Maxime Dahirel                                                                                                                                              |
| 746 |    956.326950 |     77.898312 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 747 |    749.253160 |    306.272292 | NA                                                                                                                                                          |
| 748 |    602.914055 |      5.438262 | Duane Raver/USFWS                                                                                                                                           |
| 749 |    723.024331 |    276.441550 | Lukasiniho                                                                                                                                                  |
| 750 |    124.140372 |    316.742020 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                          |
| 751 |    752.433795 |    555.951465 | Chris huh                                                                                                                                                   |
| 752 |    378.806852 |    370.328206 | Margot Michaud                                                                                                                                              |
| 753 |    722.702225 |    792.216468 | Chloé Schmidt                                                                                                                                               |
| 754 |    985.636995 |    555.206085 | Margot Michaud                                                                                                                                              |
| 755 |    643.219691 |    695.318915 | Roberto Díaz Sibaja                                                                                                                                         |
| 756 |     11.377764 |     21.256453 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                         |
| 757 |    466.141040 |    501.035711 | John Curtis (vectorized by T. Michael Keesey)                                                                                                               |
| 758 |    885.443720 |    254.097932 | Crystal Maier                                                                                                                                               |
| 759 |    463.429701 |    759.328078 | Emily Willoughby                                                                                                                                            |
| 760 |    690.295091 |    456.307012 | NA                                                                                                                                                          |
| 761 |    905.957792 |    436.259559 | Dave Angelini                                                                                                                                               |
| 762 |    565.809260 |    425.131336 | Matt Crook                                                                                                                                                  |
| 763 |    173.123861 |    198.878242 | Gabriela Palomo-Munoz                                                                                                                                       |
| 764 |    242.388270 |    302.946626 | Matt Crook                                                                                                                                                  |
| 765 |     10.671596 |    425.540697 | Steven Traver                                                                                                                                               |
| 766 |    780.611010 |    558.500320 | James R. Spotila and Ray Chatterji                                                                                                                          |
| 767 |    949.522058 |    324.342268 | Emily Willoughby                                                                                                                                            |
| 768 |    474.595564 |    494.323690 | Zimices                                                                                                                                                     |
| 769 |     63.489289 |    339.705867 | Steven Traver                                                                                                                                               |
| 770 |    805.070046 |    646.717121 | Pete Buchholz                                                                                                                                               |
| 771 |    282.538059 |    608.111613 | Scott Hartman                                                                                                                                               |
| 772 |    771.347480 |    358.413222 | Margot Michaud                                                                                                                                              |
| 773 |    374.911036 |     11.387217 | NA                                                                                                                                                          |
| 774 |    131.777767 |     29.150441 | Lukasiniho                                                                                                                                                  |
| 775 |    497.202161 |     89.136413 | Peileppe                                                                                                                                                    |
| 776 |    300.135209 |    281.993098 | NA                                                                                                                                                          |
| 777 |    372.187735 |    244.640664 | Shyamal                                                                                                                                                     |
| 778 |    581.061068 |    222.923548 | Zimices                                                                                                                                                     |
| 779 |     80.221636 |    247.463085 | Steven Traver                                                                                                                                               |
| 780 |    827.003083 |    104.346780 | Steven Traver                                                                                                                                               |
| 781 |    678.538922 |     16.903083 | S.Martini                                                                                                                                                   |
| 782 |    502.783301 |    386.571305 | Maija Karala                                                                                                                                                |
| 783 |    990.112426 |    506.958558 | NA                                                                                                                                                          |
| 784 |    496.110400 |    571.415361 | Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong)                                                                                             |
| 785 |    750.687948 |    214.675011 | Matt Crook                                                                                                                                                  |
| 786 |   1007.824846 |    735.965166 | Zimices                                                                                                                                                     |
| 787 |    639.453613 |    241.727320 | NA                                                                                                                                                          |
| 788 |    514.599284 |    636.318113 | Jonathan Wells                                                                                                                                              |
| 789 |    609.414635 |    294.536751 | Emily Willoughby                                                                                                                                            |
| 790 |    657.620313 |    625.142360 | Margot Michaud                                                                                                                                              |
| 791 |    774.929300 |    786.349244 | Matt Crook                                                                                                                                                  |
| 792 |    221.045979 |     24.243010 | Zimices                                                                                                                                                     |
| 793 |    589.225463 |     78.840632 | Mike Hanson                                                                                                                                                 |
| 794 |    112.605990 |    196.244117 | FunkMonk                                                                                                                                                    |
| 795 |    344.154411 |    306.533080 | Scott Hartman                                                                                                                                               |
| 796 |    436.881201 |    667.258544 | Matt Crook                                                                                                                                                  |
| 797 |    435.263538 |    458.073987 | T. Michael Keesey                                                                                                                                           |
| 798 |    983.539197 |    631.796331 | . Original drawing by M. Antón, published in Montoya and Morales 1984. Vectorized by O. Sanisidro                                                           |
| 799 |    556.914404 |     13.209264 | Margot Michaud                                                                                                                                              |
| 800 |    376.887245 |    160.397884 | Zimices                                                                                                                                                     |
| 801 |    665.903743 |    434.569177 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                     |
| 802 |    174.772708 |    795.279266 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 803 |    349.729905 |    604.072308 | Sean McCann                                                                                                                                                 |
| 804 |   1010.879702 |    529.597872 | Ferran Sayol                                                                                                                                                |
| 805 |    386.820033 |    472.378893 | Steven Traver                                                                                                                                               |
| 806 |    512.549913 |    519.348771 | Maija Karala                                                                                                                                                |
| 807 |    664.916042 |    640.847413 | Gareth Monger                                                                                                                                               |
| 808 |    108.562064 |    633.462271 | T. Michael Keesey                                                                                                                                           |
| 809 |    177.675703 |    552.834793 | NA                                                                                                                                                          |
| 810 |    656.598653 |    448.376663 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                 |
| 811 |    990.646442 |    579.583253 | Joanna Wolfe                                                                                                                                                |
| 812 |   1002.133996 |    307.716918 | Mathilde Cordellier                                                                                                                                         |
| 813 |    539.574787 |    488.654714 | Sam Droege (photo) and T. Michael Keesey (vectorization)                                                                                                    |
| 814 |    725.674799 |    310.782982 | Ferran Sayol                                                                                                                                                |
| 815 |    799.580028 |    269.346485 | Margot Michaud                                                                                                                                              |
| 816 |    191.677634 |      1.993031 | Smokeybjb                                                                                                                                                   |
| 817 |    795.794203 |    557.075710 | Zimices                                                                                                                                                     |
| 818 |    751.697805 |    223.167276 | Jagged Fang Designs                                                                                                                                         |
| 819 |    532.222062 |    117.903797 | Felix Vaux                                                                                                                                                  |
| 820 |    937.402635 |    779.365465 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                            |
| 821 |    492.659989 |    213.244192 | Melissa Broussard                                                                                                                                           |
| 822 |    786.040733 |      9.848655 | Scott Hartman                                                                                                                                               |
| 823 |    446.315553 |    714.926351 | Steven Traver                                                                                                                                               |
| 824 |     60.785981 |    168.374832 | Christoph Schomburg                                                                                                                                         |
| 825 |     48.453217 |    737.455036 | NA                                                                                                                                                          |
| 826 |    341.209620 |    275.796016 | NA                                                                                                                                                          |
| 827 |    845.899270 |     62.899519 | NA                                                                                                                                                          |
| 828 |    268.442506 |    730.330335 | Chase Brownstein                                                                                                                                            |
| 829 |    397.249289 |    459.875977 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                            |
| 830 |    751.365891 |    323.145212 | Smokeybjb (modified by T. Michael Keesey)                                                                                                                   |
| 831 |    274.890458 |    144.494573 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 832 |   1007.310477 |    756.183720 | Gareth Monger                                                                                                                                               |
| 833 |    325.182919 |     98.459208 | Gareth Monger                                                                                                                                               |
| 834 |    745.543173 |    115.823263 | Melissa Broussard                                                                                                                                           |
| 835 |     18.696036 |    460.287442 | Collin Gross                                                                                                                                                |
| 836 |    462.530268 |    144.776148 | Smokeybjb                                                                                                                                                   |
| 837 |    985.369498 |    402.640998 | Zimices                                                                                                                                                     |
| 838 |    394.641022 |    722.267235 | Felix Vaux                                                                                                                                                  |
| 839 |    284.519608 |    723.837623 | Shyamal                                                                                                                                                     |
| 840 |    173.063900 |    336.922481 | Christoph Schomburg                                                                                                                                         |
| 841 |   1009.346440 |    423.540796 | Michael P. Taylor                                                                                                                                           |
| 842 |    944.941524 |    150.018925 | Yan Wong from drawing by Joseph Smit                                                                                                                        |
| 843 |   1012.108832 |    583.845581 | Zimices                                                                                                                                                     |
| 844 |    702.063396 |    305.642365 | T. Michael Keesey                                                                                                                                           |
| 845 |    475.816746 |    369.753158 | Scott Hartman                                                                                                                                               |
| 846 |    420.096549 |    282.601255 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                           |
| 847 |    606.918783 |    389.631616 | Zimices                                                                                                                                                     |
| 848 |    954.923039 |    632.965355 | Smokeybjb                                                                                                                                                   |
| 849 |    434.627087 |    266.708346 | Zimices                                                                                                                                                     |
| 850 |     63.131965 |    456.146018 | Jagged Fang Designs                                                                                                                                         |
| 851 |     21.079719 |    763.234431 | Scott Hartman                                                                                                                                               |
| 852 |    245.426143 |    136.555904 | Noah Schlottman                                                                                                                                             |
| 853 |    959.843669 |    622.332789 | Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong)                                                                                             |
| 854 |      6.298107 |    666.656395 | Rebecca Groom                                                                                                                                               |
| 855 |     25.176402 |    495.760671 | Aviceda (photo) & T. Michael Keesey                                                                                                                         |
| 856 |    164.599768 |    295.269115 | Gareth Monger                                                                                                                                               |
| 857 |    553.564016 |    235.727417 | NA                                                                                                                                                          |
| 858 |     43.454057 |    691.773989 | Jakovche                                                                                                                                                    |
| 859 |    249.472017 |    743.549006 | Matt Martyniuk                                                                                                                                              |
| 860 |    385.943858 |    610.924459 | Sarah Werning                                                                                                                                               |
| 861 |    428.880053 |    439.826655 | Gareth Monger                                                                                                                                               |
| 862 |    567.417046 |     75.017282 | Zimices                                                                                                                                                     |
| 863 |    255.444574 |    113.417432 | Jagged Fang Designs                                                                                                                                         |
| 864 |    192.806257 |    204.711543 | T. Michael Keesey                                                                                                                                           |
| 865 |    618.612800 |    587.139454 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                               |
| 866 |     62.206714 |    140.259347 | Anthony Caravaggi                                                                                                                                           |
| 867 |    732.721512 |    597.731668 | Matt Crook                                                                                                                                                  |
| 868 |    289.890918 |    112.902753 | Margot Michaud                                                                                                                                              |
| 869 |    626.001966 |    573.984771 | Steven Traver                                                                                                                                               |
| 870 |    834.592757 |    556.426258 | Jagged Fang Designs                                                                                                                                         |
| 871 |     25.289278 |     54.159975 | L. Shyamal                                                                                                                                                  |
| 872 |    699.135956 |    444.414713 | L. Shyamal                                                                                                                                                  |
| 873 |    380.633048 |    724.032565 | Matt Crook                                                                                                                                                  |
| 874 |    999.138518 |    371.759939 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                   |
| 875 |    567.505759 |    705.677585 | T. Michael Keesey (photo by Bc999 \[Black crow\])                                                                                                           |
| 876 |    822.035132 |    172.964792 | Jonathan Wells                                                                                                                                              |
| 877 |    168.715449 |    672.346829 | Smokeybjb                                                                                                                                                   |
| 878 |    132.565279 |    194.745015 | Anthony Caravaggi                                                                                                                                           |
| 879 |     43.859881 |    136.370417 | NA                                                                                                                                                          |
| 880 |    481.857739 |    191.976897 | Mathilde Cordellier                                                                                                                                         |
| 881 |    875.713875 |    507.621848 | Mali’o Kodis, drawing by Manvir Singh                                                                                                                       |
| 882 |    657.153327 |    562.846531 | xgirouxb                                                                                                                                                    |
| 883 |    587.459076 |    283.123368 | C. Camilo Julián-Caballero                                                                                                                                  |
| 884 |    797.488736 |    618.869809 | Zimices                                                                                                                                                     |
| 885 |    684.111311 |    125.382030 | E. J. Van Nieukerken, A. Laštuvka, and Z. Laštuvka (vectorized by T. Michael Keesey)                                                                        |
| 886 |    996.455351 |     63.389606 | Craig Dylke                                                                                                                                                 |
| 887 |    461.352572 |    553.062665 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                     |
| 888 |    817.291272 |    771.598783 | Zimices                                                                                                                                                     |
| 889 |    214.953036 |    252.888846 | Xavier Giroux-Bougard                                                                                                                                       |
| 890 |    370.268046 |    180.134615 | NA                                                                                                                                                          |
| 891 |     11.476463 |    652.757162 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 892 |    998.362420 |     44.246162 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                            |
| 893 |    252.173674 |    120.365723 | Scott Hartman                                                                                                                                               |
| 894 |     44.726440 |    169.627772 | NA                                                                                                                                                          |
| 895 |    630.860515 |    171.737371 | Zimices                                                                                                                                                     |
| 896 |    750.055299 |    299.253168 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 897 |    354.175497 |    233.957579 | Sarah Werning                                                                                                                                               |
| 898 |    350.444355 |    473.496139 | Greg Schechter (original photo), Renato Santos (vector silhouette)                                                                                          |
| 899 |    232.101568 |    638.304324 | Margot Michaud                                                                                                                                              |
| 900 |    975.669586 |    756.409601 | Gareth Monger                                                                                                                                               |
| 901 |    832.145844 |    184.490864 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                           |
| 902 |    599.613586 |    271.132443 | Tracy A. Heath                                                                                                                                              |
| 903 |    320.237593 |    269.055057 | Filip em                                                                                                                                                    |
| 904 |    548.997388 |    223.000245 | Gabriela Palomo-Munoz                                                                                                                                       |
| 905 |    776.956363 |    246.260440 | Scott Hartman                                                                                                                                               |
| 906 |    601.351626 |     44.410644 | Zimices                                                                                                                                                     |
| 907 |    601.466204 |    229.342679 | Michelle Site                                                                                                                                               |
| 908 |    141.579086 |    400.709114 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                              |
| 909 |    863.377979 |    585.769496 | Scott Hartman                                                                                                                                               |
| 910 |    806.404008 |    525.148607 | Taenadoman                                                                                                                                                  |
| 911 |    667.374459 |    709.283060 | NA                                                                                                                                                          |
| 912 |    713.274878 |    662.758795 | Zimices                                                                                                                                                     |
| 913 |    856.638781 |    464.650801 | Scott Hartman                                                                                                                                               |
| 914 |    214.850161 |    389.102279 | Óscar San-Isidro (vectorized by T. Michael Keesey)                                                                                                          |
| 915 |      9.939888 |    723.710209 | Margot Michaud                                                                                                                                              |
| 916 |    891.463770 |    158.620361 | Emily Jane McTavish, from <http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>                                                                     |
| 917 |    730.037175 |    555.768553 | Chris huh                                                                                                                                                   |
| 918 |    657.549318 |    250.067779 | Margot Michaud                                                                                                                                              |
| 919 |    469.475523 |    538.083579 | Jagged Fang Designs                                                                                                                                         |
| 920 |    446.353188 |    545.594630 | FunkMonk                                                                                                                                                    |
| 921 |    408.894780 |    468.597860 | Steven Traver                                                                                                                                               |
| 922 |    315.867482 |    333.778685 | Scott Hartman (modified by T. Michael Keesey)                                                                                                               |
| 923 |    229.946162 |    478.710023 | Jagged Fang Designs                                                                                                                                         |
| 924 |    380.929404 |    139.518715 | T. Michael Keesey                                                                                                                                           |
| 925 |    182.169123 |     49.070581 | Zimices                                                                                                                                                     |
| 926 |    393.411189 |     21.130547 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                |

    #> Your tweet has been posted!
