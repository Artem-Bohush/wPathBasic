( function _Path_s_() {

'use strict';

/**
  @module Tools/base/Path - Collection of routines to operate paths in the reliable and consistent way. Path leverages parsing, joining, extracting, normalizing, nativizing, resolving paths. Use the module to get uniform experience from playing with paths on different platforms.
*/

/**
 * @file Path.s.
 */

if( typeof module !== 'undefined' )
{

  let _ = require( '../../Tools.s' );

}

//

let _global = _global_;
let _ = _global_.wTools;
let Self = _.path = _.path || Object.create( null );

// --
// internal
// --

function Init()
{

  _.assert( _.strIs( this._rootStr ) );
  _.assert( _.strIs( this._upStr ) );
  _.assert( _.strIs( this._hereStr ) );
  _.assert( _.strIs( this._downStr ) );

  if( !this._hereUpStr )
  this._hereUpStr = this._hereStr + this._upStr;
  if( !this._downUpStr )
  this._downUpStr = this._downStr + this._upStr;

  this._upEscapedStr = _.regexpEscape( this._upStr );
  this._butDownUpEscapedStr = '(?!' + _.regexpEscape( this._downStr ) + this._upEscapedStr + ')';
  this._delDownEscapedStr = this._butDownUpEscapedStr + '((?!' + this._upEscapedStr + ').)+' + this._upEscapedStr + _.regexpEscape( this._downStr ) + '(' + this._upEscapedStr + '|$)';
  this._delDownEscaped2Str = this._butDownUpEscapedStr + '((?!' + this._upEscapedStr + ').|)+' + this._upEscapedStr + _.regexpEscape( this._downStr ) + '(' + this._upEscapedStr + '|$)';
  this._delUpRegexp = new RegExp( this._upEscapedStr + '+$' );
  this._delHereRegexp = new RegExp( this._upEscapedStr + _.regexpEscape( this._hereStr ) + '(' + this._upEscapedStr + '|$)','' );
  this._delDownRegexp = new RegExp( this._upEscapedStr + this._delDownEscaped2Str,'' );
  this._delDownFirstRegexp = new RegExp( '^' + this._delDownEscapedStr,'' );
  this._delUpDupRegexp = /\/{2,}/g;

}

//

function CloneExtending( o )
{
  _.assert( arguments.length === 1 );
  let result = Object.create( this )
  _.mapExtend( result, Parameters, o );
  result.Init();
  return result;
}

//

/*
qqq : use routineVectorize_functor instead
*/

function _pathMultiplicator_functor( o )
{

  if( _.routineIs( o ) || _.strIs( o ) )
  o = { routine : o }

  _.routineOptions( _pathMultiplicator_functor,o );
  _.assert( _.routineIs( o.routine ) );
  _.assert( o.fieldNames === null || _.longIs( o.fieldNames ) )

  /* */

  let routine = o.routine;
  let fieldNames = o.fieldNames;

  function supplement( src, l )
  {
    if( !_.longIs( src ) )
    src = _.arrayFillTimes( [], l, src );
    _.assert( src.length === l, 'routine expects arrays with same length' );
    return src;
  }

  function inputMultiplicator( o )
  {
    let result = [];
    let l = 0;
    let onlyScalars = true;

    if( arguments.length > 1 )
    {
      let args = [].slice.call( arguments );

      for( let i = 0; i < args.length; i++ )
      {
        if( onlyScalars && _.longIs( args[ i ] ) )
        onlyScalars = false;

        l = Math.max( l, _.arrayAs( args[ i ] ).length );
      }

      for( let i = 0; i < args.length; i++ )
      args[ i ] = supplement( args[ i ], l );

      for( let i = 0; i < l; i++ )
      {
        let argsForCall = [];

        for( let j = 0; j < args.length; j++ )
        argsForCall.push( args[ j ][ i ] );

        let r = routine.apply( this, argsForCall );
        result.push( r )
      }
    }
    else
    {
      if( fieldNames === null || !_.objectIs( o ) )
      {
        if( _.longIs( o ) )
        {
          for( let i = 0; i < o.length; i++ )
          result.push( routine.call( this, o[ i ] ) );
        }
        else
        {
          result = routine.call( this, o );
        }

        return result;
      }

      let fields = [];

      for( let i = 0; i < fieldNames.length; i++ )
      {
        let field = o[ fieldNames[ i ] ];

        if( onlyScalars && _.longIs( field ) )
        onlyScalars = false;

        l = Math.max( l, _.arrayAs( field ).length );
        fields.push( field );
      }

      for( let i = 0; i < fields.length; i++ )
      fields[ i ] = supplement( fields[ i ], l );

      for( let i = 0; i < l; i++ )
      {
        let options = _.mapExtend( null, o );
        for( let j = 0; j < fieldNames.length; j++ )
        {
          let fieldName = fieldNames[ j ];
          options[ fieldName ] = fields[ j ][ i ];
        }

        result.push( routine.call( this, options ) );
      }
    }

    _.assert( result.length === l );

    if( onlyScalars )
    return result[ 0 ];

    return result;
  }

  return inputMultiplicator;
}

_pathMultiplicator_functor.defaults =
{
  routine : null,
  fieldNames : null
}

//

function _filterNoInnerArray( arr )
{
  return arr.every( ( e ) => !_.arrayIs( e ) );
}

//

function _filterOnlyPath( e,k,c )
{
  if( _.strIs( k ) )
  {
    if( _.strEnds( k,'Path' ) )
    return true;
    else
    return false
  }
  return this.is( e );
}

// --
// path tester
// --

function is( path )
{
  _.assert( arguments.length === 1, 'Expects single argument' );
  return _.strIs( path );
}

//

function are( paths )
{
  let self = this;
  _.assert( arguments.length === 1, 'Expects single argument' );
  if( _.mapIs( paths ) )
  return true;
  if( !_.arrayIs( paths ) )
  return false;
  return paths.every( ( path ) => self.is( path ) );
}

//

function like( path )
{
  _.assert( arguments.length === 1, 'Expects single argument' );
  if( this.is( path ) )
  return true;
  if( _.FileRecord )
  if( path instanceof _.FileRecord )
  return true;
  return false;
}

//

/**
 * Checks if string is correct possible for current OS path and represent file/directory that is safe for modification
 * (not hidden for example).
 * @param filePath
 * @returns {boolean}
 * @method isSafe
 * @memberof wTools
 */

function isSafe( filePath, level )
{
  filePath = this.normalize( filePath );

  if( level === undefined )
  level = 1;

  _.assert( arguments.length === 1 || arguments.length === 2 );
  _.assert( _.numberIs( level ), 'Expects number {- level -}' );

  if( level >= 1 )
  {
    let isAbsolute = this.isAbsolute( filePath );
    if( isAbsolute )
    if( this.isAbsolute( filePath ) )
    {
      // debugger;
      let parts = filePath.split( this._upStr ).filter( ( p ) => p.trim() );
      let number = parts.lenth;
      if( process.platform === 'win32' && parts.length && parts[ 0 ].length === 1 )
      parts.splice( 0,1 )
      if( parts.length <= 1 )
      return false;
      if( level >= 2 && parts.length <= 2 )
      return false;
      return true;
    }
  }

  if( level >= 2 && process.platform === 'win32' )
  {
    if( _.strHas( filePath, 'Windows' ) )
    return false;
    if( _.strHas( filePath, 'Program Files' ) )
    return false;
  }

  if( level >= 2 )
  if( /(^|\/)\.(?!$|\/|\.)/.test( filePath ) )
  return false;

  // if( level >= 1 )
  // if( filePath.indexOf( '/' ) === 1 )
  // if( filePath[ 0 ] === '/' )
  // {
  //   throw _.err( 'not tested' );
  //   return false;
  // }

  if( level >= 3 )
  if( /(^|\/)node_modules($|\/)/.test( filePath ) )
  return false;

  // if( safe )
  // safe = filePath.length > 8 || ( filePath[ 0 ] !== '/' && filePath[ 1 ] !== ':' );

  return true;
}

//

function isNormalized( path )
{
  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( _.strIs( path ) );
  return this.normalize( path ) === path;
}

//

function isRefined( path )
{
  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( _.strIs( path ), 'Expects string {-path-}, but got', _.strTypeOf( path ) );

  if( !path.length )
  return false;

  if( path[ 1 ] === ':' && path[ 2 ] === '\\' )
  return false;

  let leftSlash = /\\/g;
  let doubleSlash = /\/\//g;

  if( leftSlash.test( path ) /* || doubleSlash.test( path ) */ )
  return false;

  /* check right "/" */
  if( path !== this._upStr && !_.strEnds( path,this._upStr + this._upStr ) && _.strEnds( path,this._upStr ) )
  return false;

  return true;
}

//

function isAbsolute( path )
{
  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( _.strIs( path ), 'Expects string {-path-}, but got', _.strTypeOf( path ) );
  _.assert( path.indexOf( '\\' ) === -1,'Expects normalized {-path-}, but got', path );
  return _.strBegins( path,this._upStr );
}

//

function isRelative( path )
{
  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( _.strIs( path ), 'Expects string {-path-}, but got', _.strTypeOf( path ) );
  return !this.isAbsolute( path );
}

//

function isGlobal( path )
{
  _.assert( _.strIs( path ) );
  return _.strHas( path, '://' );
}

//

function isRoot( path )
{
  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( _.strIs( path ), 'Expects string {-path-}, but got', _.strTypeOf( path ) );
  return path === this._rootStr;
}

//

function isDotted( srcPath )
{
  return _.strBegins( srcPath, this._hereStr );
}

//

function isTrailed( srcPath )
{
  if( srcPath === this._rootStr )
  return false;
  return _.strEnds( srcPath, this._upStr );
}

//

function begins( srcPath, beginPath )
{
  if( srcPath === beginPath )
  return true;
  return _.strBegins( srcPath, this.trail( beginPath ) );
}

//

function ends( srcPath, endPath )
{
  endPath = this.undot( endPath );
  if( !_.strEnds( srcPath, endPath ) )
  return false;

  let begin = _.strRemoveEnd( srcPath, endPath );
  if( begin === '' || _.strEnds( begin, this._upStr ) || _.strEnds( begin, this._hereStr ) )
  return true;

  return false;
}

// --
// normalizer
// --

function refine( src )
{

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( _.strIs( src ) );

  if( !src.length )
  return this._hereStr;

  let result = src;

  if( result[ 1 ] === ':' && ( result[ 2 ] === '\\' || result[ 2 ] === '/' || result.length === 2 ) )
  result = '/' + result[ 0 ] + '/' + result.substring( 3 );

  result = result.replace( /\\/g, '/' );

  /* remove right "/" */

  if( result !== this._upStr && !_.strEnds( result, this._upStr + this._upStr ))
  result = _.strRemoveEnd( result,this._upStr );

  // if( result !== this._upStr )
  // result = result.replace( this._delUpRegexp, '' );

  return result;
}

//

function _pathNormalize( o )
{
  if( !o.src.length )
  return '.';

  let result = o.src;
  let endsWithUpStr = o.src === this._upStr || _.strEnds( o.src,this._upStr );
  result = this.refine( o.src );
  let beginsWithHere = o.src === this._hereStr || _.strBegins( o.src,this._hereUpStr ) || _.strBegins( o.src, this._hereStr + '\\' );

  /* remove "." */

  if( result.indexOf( this._hereStr ) !== -1 )
  {
    while( this._delHereRegexp.test( result ) )
    result = result.replace( this._delHereRegexp,this._upStr );
  }

  if( _.strBegins( result,this._hereUpStr ) && !_.strBegins( result, this._hereUpStr + this._upStr ) )
  result = _.strRemoveBegin( result,this._hereUpStr );

  /* remove ".." */

  if( result.indexOf( this._downStr ) !== -1 )
  {
    while( this._delDownRegexp.test( result ) )
    result = result.replace( this._delDownRegexp,this._upStr );
  }

  /* remove first ".." */

  if( result.indexOf( this._downStr ) !== -1 )
  {
    while( this._delDownFirstRegexp.test( result ) )
    result = result.replace( this._delDownFirstRegexp,'' );
  }

  if( !o.tolerant )
  {
    /* remove right "/" */

    if( result !== this._upStr && !_.strEnds( result, this._upStr + this._upStr ) )
    result = _.strRemoveEnd( result,this._upStr );
  }
  else
  {
    /* remove "/" duplicates */

    result = result.replace( this._delUpDupRegexp, this._upStr );

    if( endsWithUpStr )
    result = _.strAppendOnce( result, this._upStr );
  }

  /* nothing left */

  if( !result.length )
  result = '.';

  /* get back left "." */

  if( beginsWithHere )
  result = this.dot( result );

  return result;
}

//

/**
 * Regularize a path by collapsing redundant delimeters and resolving '..' and '.' segments, so A//B, A/./B and
    A/foo/../B all become A/B. This string manipulation may change the meaning of a path that contains symbolic links.
    On Windows, it converts forward slashes to backward slashes. If the path is an empty string, method returns '.'
    representing the current working directory.
 * @example
   let path = '/foo/bar//baz1/baz2//some/..'
   path = wTools.normalize( path ); // /foo/bar/baz1/baz2
 * @param {string} src path for normalization
 * @returns {string}
 * @method normalize
 * @memberof wTools
 */

function normalize( src )
{
  let result = this._pathNormalize({ src : src, tolerant : false });

  _.assert( _.strIs( src ), 'Expects string' );
  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( result.length > 0 );
  _.assert( result === this._upStr || _.strEnds( result,this._upStr + this._upStr ) ||  !_.strEnds( result,this._upStr ) );
  _.assert( result.lastIndexOf( this._upStr + this._hereStr + this._upStr ) === -1 );
  _.assert( !_.strEnds( result,this._upStr + this._hereStr ) );

  if( Config.debug )
  {
    let i = result.lastIndexOf( this._upStr + this._downStr + this._upStr );
    _.assert( i === -1 || !/\w/.test( result.substring( 0,i ) ) );
  }

  return result;
}

//

function normalizeTolerant( src )
{
  _.assert( _.strIs( src ),'Expects string' );

  let result = this._pathNormalize({ src : src, tolerant : true });

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( result.length > 0 );
  _.assert( result === this._upStr || _.strEnds( result,this._upStr ) || !_.strEnds( result,this._upStr + this._upStr ) );
  _.assert( result.lastIndexOf( this._upStr + this._hereStr + this._upStr ) === -1 );
  _.assert( !_.strEnds( result,this._upStr + this._hereStr ) );

  if( Config.debug )
  {
    _.assert( !this._delUpDupRegexp.test( result ) );
  }

  return result;
}

//

function dot( path )
{

  _.assert( !_.path.isAbsolute( path ) );
  _.assert( arguments.length === 1 );

  if( path !== this._hereStr && !_.strBegins( path,this._hereUpStr ) && path !== this._downStr && !_.strBegins( path,this._downUpStr ) )
  {
    _.assert( !_.strBegins( path,this._upStr ) );
    path = this._hereUpStr + path;
  }

  // _rootStr : '/',
  // _upStr : '/',
  // _hereStr : '.',
  // _downStr : '..',

  return path;
}

//

function undot( path )
{
  return _.strRemoveBegin( path, this._hereUpStr );
}

//

function trail( srcPath )
{
  _.assert( _.path.is( srcPath ) );
  _.assert( arguments.length === 1 );

  if( !_.strEnds( srcPath, this._upStr ) )
  return srcPath + this._upStr;

  return srcPath;
}

//

function detrail( path )
{
  _.assert( _.path.is( path ) );
  _.assert( arguments.length === 1 );

  if( path !== this._rootStr )
  return _.strRemoveEnd( path, this._upStr );

  return path;
}

//

function _pathNativizeWindows( filePath )
{
  let self = this;
  _.assert( _.strIs( filePath ) ) ;
  let result = filePath.replace( /\//g, '\\' );

  if( result[ 0 ] === '\\' )
  if( result.length === 2 || result[ 2 ] === ':' || result[ 2 ] === '\\' )
  result = result[ 1 ] + ':' + result.substring( 2 );

  return result;
}

//

function _pathNativizeUnix( filePath )
{
  let self = this;
  _.assert( _.strIs( filePath ) );
  return filePath;
}

//

let nativize;
if( _global.process && _global.process.platform === 'win32' )
nativize = _pathNativizeWindows;
else
nativize = _pathNativizeUnix;

// --
// path join
// --

/**
 * Joins filesystem paths fragments or urls fragment into one path/url. Uses '/' level delimeter.
 * @param {Object} o join o.
 * @param {String[]} p.paths - Array with paths to join.
 * @param {boolean} [o.reroot=false] If this parameter set to false (by default), method joins all elements in
 * `paths` array, starting from element that begins from '/' character, or '* :', where '*' is any drive name. If it
 * is set to true, method will join all elements in array. Result
 * @returns {string}
 * @private
 * @throws {Error} If missed arguments.
 * @throws {Error} If elements of `paths` are not strings
 * @throws {Error} If o has extra parameters.
 * @method _pathJoinAct
 * @memberof wTools
 */

function _pathJoinAct( o )
{
  let self = this;
  let result = null;
  let prepending = true;

  /* */

  _.assert( Object.keys( o ).length === 3 );
  _.assert( o.paths.length > 0 );
  _.assert( _.boolLike( o.reroot ) );

  /* */

  for( let a = o.paths.length-1 ; a >= 0 ; a-- )
  {
    let src = o.paths[ a ];
    _.sure( _.strIs( src ) || src === null, () => 'Expects strings as path arguments, but #' + a + ' argument is ' + _.strTypeOf( src ) );
  }

  /* */

  for( let a = o.paths.length-1 ; a >= 0 ; a-- )
  {
    let src = o.paths[ a ];

    if( o.allowingNull )
    if( src === null )
    break;

    if( result === null )
    result = '';

    // _.assert( _.strIs( src ), () => 'Expects strings as path arguments, but #' + a + ' argument is ' + _.strTypeOf( src ) );

    prepending = prepend( src );
    if( prepending === false )
    break;

  }

  /* */

  if( result === '' )
  return '.';

  return result;

  /* */

  function prepend( src )
  {

    if( src )
    src = self.refine( src );

    if( !src )
    return prepending;

    let doPrepend = prepending;

    if( doPrepend )
    {

      src = src.replace( /\\/g, '/' );

      if( result && src[ src.length-1 ] === '/' && !_.strEnds( src, '//' ) )
      if( src.length > 1 || result[ 0 ] === '/' )
      src = src.substr( 0,src.length-1 );

      if( src && src[ src.length-1 ] !== '/' && result && result[ 0 ] !== '/' )
      result = '/' + result;

      result = src + result;

    }

    if( !o.reroot )
    {
      if( src[ 0 ] === '/' )
      return false;
    }

    return prepending;
  }

}

_pathJoinAct.defaults =
{
  paths : null,
  reroot : 0,
  allowingNull : 1,
}

//

// function _pathsJoin_body( o )
// {
//   let isArray = false;
//   let length = 0;
//
//   /* */
//
//   for( let p = 0 ; p < o.paths.length ; p++ )
//   {
//     let path = o.paths[ p ];
//     if( _.arrayIs( path ) )
//     {
//       _.assert( _filterNoInnerArray( path ), 'Array must not have inner array( s ).' )
//
//       if( isArray )
//       _.assert( path.length === length, 'Arrays must have same length.' );
//       else
//       {
//         length = Math.max( path.length,length );
//         isArray = true;
//       }
//     }
//     else
//     {
//       length = Math.max( 1,length );
//     }
//   }
//
//   if( isArray === false )
//   return this._pathJoinAct( o );
//
//   /* */
//
//   let paths = o.paths;
//   function argsFor( i )
//   {
//     let res = [];
//     for( let p = 0 ; p < paths.length ; p++ )
//     {
//       let path = paths[ p ];
//       if( _.arrayIs( path ) )
//       res[ p ] = path[ i ];
//       else
//       res[ p ] = path;
//     }
//     return res;
//   }
//
//   /* */
//
//   let result = new Array( length );
//   for( let i = 0 ; i < length ; i++ )
//   {
//     o.paths = argsFor( i );
//     result[ i ] = this._pathJoinAct( o );
//   }
//
//   return result;
// }

//

/**
 * Method joins all `paths` together, beginning from string that starts with '/', and normalize the resulting path.
 * @example
 * let res = wTools.join( '/foo', 'bar', 'baz', '.');
 * // '/foo/bar/baz'
 * @param {...string} paths path strings
 * @returns {string} Result path is the concatenation of all `paths` with '/' directory delimeter.
 * @throws {Error} If one of passed arguments is not string
 * @method join
 * @memberof wTools
 */

function join()
{

  let result = this._pathJoinAct
  ({
    paths : arguments,
    reroot : 0,
    allowingNull : 1,
  });

  return result;
}

//

function joinIfDefined()
{
  let args = _.filter( arguments, ( arg ) => arg );
  if( !args.length )
  return;
  return this.join.apply( this, args );
}

//

function crossJoin()
{

  if( _.arrayHasArray( arguments ) )
  {

    let result = [];
    let samples = _.eachSample( arguments );
    for( var s = 0 ; s < samples.length ; s++ )
    result.push( this.join.apply( this, samples[ s ] ) );
    return result;

  }

  return this.join.apply( this, arguments );
}

//

/**
 * Method joins all `paths` strings together.
 * @example
 * let res = wTools.reroot( '/foo', '/bar/', 'baz', '.');
 * // '/foo/bar/baz/.'
 * @param {...string} paths path strings
 * @returns {string} Result path is the concatenation of all `paths` with '/' directory delimeter.
 * @throws {Error} If one of passed arguments is not string
 * @method reroot
 * @memberof wTools
 */

function reroot()
{
  let result = this._pathJoinAct
  ({
    paths : arguments,
    reroot : 1,
    allowingNull : 1,
  });
  return result;
}

//

/**
 * Method resolves a sequence of paths or path segments into an absolute path.
 * The given sequence of paths is processed from right to left, with each subsequent path prepended until an absolute
 * path is constructed. If after processing all given path segments an absolute path has not yet been generated,
 * the current working directory is used.
 * @example
 * let absPath = wTools.resolve('work/wFiles'); // '/home/user/work/wFiles';
 * @param [...string] paths A sequence of paths or path segments
 * @returns {string}
 * @method resolve
 * @memberof wTools
 */

function resolve()
{
  let path;

  _.assert( arguments.length > 0 );

  path = this.join.apply( this, arguments );

  if( path === null )
  return path;
  else if( !this.isAbsolute( path ) )
  path = this.join( this.current(), path );

  path = this.normalize( path );

  _.assert( path.length > 0 );

  return path;
}

// --
// path cut off
// --

/**
 * Returns the directory name of `path`.
 * @example
 * let path = '/foo/bar/baz/text.txt'
 * wTools.dir( path ); // '/foo/bar/baz'
 * @param {string} path path string
 * @returns {string}
 * @throws {Error} If argument is not string
 * @method dir
 * @memberof wTools
 */

function dir( path )
{

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( _.strDefined( path ) , 'dir','Expects not empty string ( path )' );

  // if( path.length > 1 )
  // if( path[ path.length-1 ] === '/' && path[ path.length-2 ] !== '/' )
  // path = path.substr( 0,path.length-1 )

  path = this.refine( path );

  if( path === this._rootStr )
  {
    return path + this._downStr;
  }

  if( _.strEnds( path,this._upStr + this._downStr ) || path === this._downStr )
  {
    return path + this._upStr + this._downStr;
  }

  let i = path.lastIndexOf( this._upStr );

  if( i === -1 )
  {

    if( path === this._hereStr )
    return this._downStr;
    else
    return this._hereStr;

  }

  if( path[ i - 1 ] === '/' )
  return path;

  let result = path.substr( 0,i );

  // _.assert( result.length > 0 );

  if( result === '' )
  result = this._rootStr;

  return result;
}

//

function _split( path )
{
  return path.split( this._upStr );
}

//

function split( path )
{
  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( _.strIs( path ) )
  let result = this._split( this.refine( path ) );
  return result;
}

//

/**
 * Returns dirname + filename without extension
 * @example
 * _.path.prefixGet( '/foo/bar/baz.ext' ); // '/foo/bar/baz'
 * @param {string} path Path string
 * @returns {string}
 * @throws {Error} If passed argument is not string.
 * @method prefixGet
 * @memberof wTools
 */

function prefixGet( path )
{

  if( !_.strIs( path ) )
  throw _.err( 'prefixGet :','Expects strings as path' );

  let n = path.lastIndexOf( '/' );
  if( n === -1 ) n = 0;

  let parts = [ path.substr( 0,n ),path.substr( n ) ];

  n = parts[ 1 ].indexOf( '.' );
  if( n === -1 )
  n = parts[ 1 ].length;

  let result = parts[ 0 ] + parts[ 1 ].substr( 0, n );

  return result;
}

//

/**
 * Returns path name (file name).
 * @example
 * wTools.name( '/foo/bar/baz.asdf' ); // 'baz'
 * @param {string|object} path|o Path string, or options
 * @param {boolean} o.withExtension if this parameter set to true method return name with extension.
 * @returns {string}
 * @throws {Error} If passed argument is not string
 * @method name
 * @memberof wTools
 */

function name( o )
{

  if( _.strIs( o ) )
  o = { path : o };

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.routineOptions( name,o );
  _.assert( _.strIs( o.path ), 'Expects strings {-o.path-}' );

  let i = o.path.lastIndexOf( '/' );
  if( i !== -1 )
  o.path = o.path.substr( i+1 );

  if( !o.withExtension )
  {
    let i = o.path.lastIndexOf( '.' );
    if( i !== -1 ) o.path = o.path.substr( 0,i );
  }

  return o.path;
}

name.defaults =
{
  path : null,
  withExtension : 0,
}

//

function fullName( path )
{

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( _.strIs( path ), 'Expects strings {-path-}' );

  let i = path.lastIndexOf( '/' );
  if( i !== -1 )
  path = path.substr( i+1 );

  return path;
}

//

function nameJoin()
{
  let prefixs = [];
  let names = [];
  let exts = [];
  let extsBool = false;
  let prefixBool = false;
  let start = -1;
  let numStarts = 0;
  let numNull = 0;
  let longerI = -1;
  let maxPrefNum = 0;

  if( Config.debug )
  for( let a = arguments.length-1 ; a >= 0 ; a-- )
  {
    let src = arguments[ a ];
    _.assert( _.strIs( src ) || src === null );
  }

  for( let a = arguments.length-1 ; a >= 0 ; a-- )
  {
    let src = arguments[ a ];
    logger.log( 'Element', a,'is:', src )
    logger.log('PREFIXES', prefixs)

    if( src === null )
    {
      prefixs.splice( 0, a + 1 );
      numNull = numNull + a + 1;
      break;
    }

    src = _.path.normalize(  src );

    let prefix = this.prefixGet( src );
    logger.log('Prefix', prefix)

    if( prefix.charAt( 0 ) === '/' )
    {
      prefixs[ a ] = src + '/';
      names[ a ] = '';
      exts[ a ] = '';
      start = a;
      numStarts = numStarts + 1;
    }
    else
    {
      names[ a ] = this.name( src );
      prefixs[ a ] = prefix.substring( 0, prefix.length - ( names[ a ].length + 1 ) );
      prefix = prefix.substring( 0, prefix.length - ( names[ a ].length ) );
      exts[ a ] = this.ext( src );

      if( prefix.substring( 0, 2 ) === './')
      {
        prefixs[ a ] = prefixs[ a ].substring( 2 );
      }

      prefixs[ a ] = prefixs[ a ].split("/");

      let prefNum = prefixs[ a ].length;

      if( maxPrefNum < prefNum )
      {
        maxPrefNum = prefNum;
        longerI = a;
      }

      let empty = prefixs[ a ][ 0 ] === '' && names[ a ] === '' && exts[ a ] === '';
      logger.log('EMpty', empty, prefixs[ a ][ 0 ], names[ a ], exts[ a ] )
      if( empty && src.charAt( 0 ) === '.' )
      exts[ a ] = src.substring( 1 );

    }

    if( exts[ a ] !== '' )
    extsBool = true;

    if( prefix !== '' )
    prefixBool = true;

    logger.log('Pre:', prefixs[ a ] )
    logger.log('Name:', names[ a ] )
    logger.log('Ext:', exts[ a ] )
    logger.log('' )
  }
  logger.log('LONGER', longerI)
  longerI = longerI - numStarts - numNull;
  logger.log('Longer',  numStarts,longerI)
  let result = names.join( '' );

  if( prefixBool === true )
  {
    if( start !== -1 )
    {
      logger.log( prefixs, start)
      var first = prefixs.splice( start, 1 );
      logger.log('first', first)
      logger.log('pref', prefixs)
    }

    logger.log('Max', maxPrefNum, prefixs)
    for( let p = 0; p < maxPrefNum; p++ )
    {
      for( let j = prefixs.length - 1; j >= 0; j-- )
      {
        let pLong = prefixs[ longerI ][ maxPrefNum - 1 - p ];
        let pj = prefixs[ j ][ prefixs[ j ].length - 1 - p ];
        if( j !== longerI )
        {
          if( pj !== undefined && pLong !== undefined )
          {
            logger.log( 'Indices', j,pj, pLong)
            if( j < longerI )
            {
              //prefixs[ longer ][ maxPref - 1 - p ] = pj + pLong;
            prefixs[ longerI ][ maxPrefNum - 1 - p ] =  _.path.nameJoin.apply( _.path, [ pj, pLong ] );
            }
            else
            {
              //prefixs[ longer ][ maxPref - 1 - p ] =  pLong + pj;
              prefixs[ longerI ][ maxPrefNum - 1 - p ] =  _.path.nameJoin.apply( _.path, [ pLong, pj ] );
            }
          }
          else if( pLong === undefined  )
          {
            prefixs[ longerI ][ maxPref - 1 - p ] =  pj;
          }
          else if( pj === undefined  )
          {
            prefixs[ longerI ][ maxPrefNum - 1 - p ] =  pLong;
          }
        }
      }
    }
    logger.log('FInal p', prefixs[ longerI ])
    let pre = _.path.join.apply( _.path, prefixs[ longerI ] );
    result = _.path.join.apply( _.path, [ pre, result ] );

    if( start !== -1 )
    {
      result =  _.path.join.apply( _.path, [ first[ 0 ], result ] )
    }

  }

  if( extsBool === true )
  {
    result = result + '.' + exts.join( '' );
  }

  result = _.path.normalize( result );

  return result;
}

/*
function nameJoin()
{
  let names = [];
  let exts = [];

  if( Config.debug )
  for( let a = arguments.length-1 ; a >= 0 ; a-- )
  {
    let src = arguments[ a ];
    _.assert( _.strIs( src ) || src === null );
  }

  for( let a = arguments.length-1 ; a >= 0 ; a-- )
  {
    let src = arguments[ a ];
    if( src === null )
    break;
    names[ a ] = this.name( src );
    exts[ a ] = src.substring( names[ a ].length );
  }

  let result = names.join( '' ) + exts.join( '' );

  return result;
}
*/

//

/**
 * Return path without extension.
 * @example
 * wTools.withoutExt( '/foo/bar/baz.txt' ); // '/foo/bar/baz'
 * @param {string} path String path
 * @returns {string}
 * @throws {Error} If passed argument is not string
 * @method withoutExt
 * @memberof wTools
 */

function withoutExt( path )
{

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( _.strIs( path ) );

  let name = _.strIsolateEndOrNone( path,'/' )[ 2 ] || path;

  let i = name.lastIndexOf( '.' );
  if( i === -1 || i === 0 )
  return path;

  let halfs = _.strIsolateEndOrNone( path,'.' );
  return halfs[ 0 ];
}

//

/**
 * Replaces existing path extension on passed in `ext` parameter. If path has no extension, adds passed extension
    to path.
 * @example
 * wTools.changeExt( '/foo/bar/baz.txt', 'text' ); // '/foo/bar/baz.text'
 * @param {string} path Path string
 * @param {string} ext
 * @returns {string}
 * @throws {Error} If passed argument is not string
 * @method changeExt
 * @memberof wTools
 */

// qqq : extend tests

function changeExt( path,ext )
{

  if( arguments.length === 2 )
  {
    _.assert( _.strIs( ext ) );
  }
  else if( arguments.length === 3 )
  {
    let sub = arguments[ 1 ];
    let ext = arguments[ 2 ];

    _.assert( _.strIs( sub ) );
    _.assert( _.strIs( ext ) );

    let cext = this.ext( path );

    if( cext !== sub )
    return path;
  }
  else _.assert( 'Expects 2 or 3 arguments' );

  if( ext === '' )
  return this.withoutExt( path );
  else
  return this.withoutExt( path ) + '.' + ext;

}

//

function _pathsChangeExt( src )
{
  _.assert( _.longIs( src ) );
  _.assert( src.length === 2 );

  return changeExt.apply( this, src );
}

//

/**
 * Returns file extension of passed `path` string.
 * If there is no '.' in the last portion of the path returns an empty string.
 * @example
 * _.path.ext( '/foo/bar/baz.ext' ); // 'ext'
 * @param {string} path path string
 * @returns {string} file extension
 * @throws {Error} If passed argument is not string.
 * @method ext
 * @memberof wTools
 */

function ext( path )
{

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( _.strIs( path ), 'Expects string {-path-}, but got', _.strTypeOf( path ) );

  let index = path.lastIndexOf( '/' );
  if( index >= 0 )
  path = path.substr( index+1,path.length-index-1  );

  index = path.lastIndexOf( '.' );
  if( index === -1 || index === 0 )
  return '';

  index += 1;

  return path.substr( index,path.length-index ).toLowerCase();
}

//

/*
qqq : not covered by tests
*/

function exts( path )
{

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( _.strIs( path ), 'Expects string {-path-}, but got', _.strTypeOf( path ) );

  path = this.name({ path : path, withExtension : 1 });

  let exts = path.split( '.' );
  exts.splice( 0,1 );
  exts = _.entityFilter( exts , ( e ) => !e ? undefined : e.toLowerCase() );

  return exts;
}

// --
// path transformer
// --

function current()
{
  _.assert( arguments.length === 0 );
  return this._upStr;
}

//

function from( src )
{

  _.assert( arguments.length === 1, 'Expects single argument' );

  if( _.strIs( src ) )
  return src;
  else
  _.assert( 0, 'unexpected type of argument : ' + _.strTypeOf( src ) );

}

//

function _relative( o )
{
  let self = this;
  let result = '';
  let relative = this.from( o.relative );
  let path = this.from( o.path );

  _.assert( _.strIs( relative ),'relative expects string {-relative-}, but got',_.strTypeOf( relative ) );
  _.assert( _.strIs( path ) || _.arrayIs( path ) );

  if( !o.resolving )
  {
    relative = this.normalize( relative );
    path = this.normalize( path );

    let relativeIsAbsolute = this.isAbsolute( relative );
    let isAbsoulute = this.isAbsolute( path );

    _.assert( relativeIsAbsolute && isAbsoulute || !relativeIsAbsolute && !isAbsoulute, 'Resolving is disabled, paths must be both absolute or relative.' );
  }
  else
  {
    relative = this.resolve( relative );
    path = this.resolve( path );

    _.assert( this.isAbsolute( relative ) );
    _.assert( this.isAbsolute( path ) );
  }

  _.assert( relative.length > 0 );
  _.assert( path.length > 0 );

  /* */

  let common = _.strCommonLeft( relative, path );

  function goodEnd( s )
  {
    return s.length === common.length || s.substring( common.length, common.length + self._upStr.length ) === self._upStr;
  }

  while( common.length > 1 )
  {
    if( !goodEnd( relative ) || !goodEnd( path ) )
    common = common.substring( 0,common.length-1 );
    else break;
  }

  /* */

  if( common === relative )
  {
    if( path === common )
    {
      result = '.';
    }
    else
    {
      result = _.strRemoveBegin( path, common );
      if( !_.strBegins( result,this._upStr+this._upStr ) && common !== this._upStr )
      result = _.strRemoveBegin( result,this._upStr );
    }
  }
  else
  {
    relative = _.strRemoveBegin( relative,common );
    path = _.strRemoveBegin( path,common );
    let count = _.strCount( relative,this._upStr );
    if( common === this._upStr )
    count += 1;

    if( !_.strBegins( path,this._upStr+this._upStr ) && common !== this._upStr )
    path = _.strRemoveBegin( path,this._upStr );

    result = _.strDup( this._downUpStr,count ) + path;

    if( _.strEnds( result,this._upStr ) )
    _.assert( result.length > this._upStr.length );
    result = _.strRemoveEnd( result,this._upStr );

  }

  if( _.strBegins( result,this._upStr + this._upStr ) )
  result = this._hereStr + result;
  else
  result = _.strRemoveBegin( result,this._upStr );

  _.assert( result.length > 0 );
  _.assert( !_.strEnds( result,this._upStr ) );
  _.assert( result.lastIndexOf( this._upStr + this._hereStr + this._upStr ) === -1 );
  _.assert( !_.strEnds( result,this._upStr + this._hereStr ) );

  if( Config.debug )
  {
    let i = result.lastIndexOf( this._upStr + this._downStr + this._upStr );
    _.assert( i === -1 || !/\w/.test( result.substring( 0,i ) ) );
  }

  if( !o.dotted )
  if( result === '.' )
  result = '';

  return result;
}

_relative.defaults =
{
  relative : null,
  path : null,
  resolving : 0,
  dotted : 1,
}

//

/**
 * Returns a relative path to `path` from an `relative` path. This is a path computation : the filesystem is not
   accessed to confirm the existence or nature of path or start. As second argument method can accept array of paths,
   in this case method returns array of appropriate relative paths. If `relative` and `path` each resolve to the same
   path method returns '.'.
 * @example
 * let from = '/foo/bar/baz',
   pathsTo =
   [
     '/foo/bar',
     '/foo/bar/baz/dir1',
   ],
   relatives = wTools.relative( from, pathsTo ); //  [ '..', 'dir1' ]
 * @param {string|wFileRecord} relative start path
 * @param {string|string[]} path path to.
 * @returns {string|string[]}
 * @method relative
 * @memberof wTools
 */

function relative()
{

  _.assert( /* arguments.length === 1 || */ arguments.length === 2 );

  // if( arguments[ 1 ] !== undefined )
  let o = { relative : arguments[ 0 ], path : arguments[ 1 ] }

  _.routineOptions( relative, o );

  o.relative = this.from( o.relative );
  o.path = this.from( o.path );

  return this._relative( o );
}

relative.defaults = Object.create( _relative.defaults );

//

function relativeUndoted( o )
{

  if( arguments[ 1 ] !== undefined )
  {
    o = { relative : arguments[ 0 ], path : arguments[ 1 ] }
  }

  _.assert( arguments.length === 1 || arguments.length === 2 );
  _.routineOptions( relativeUndoted, o );

  let relativePath = this.from( o.relative );
  let path = this.from( o.path );

  return this._relative( o );
}

relativeUndoted.defaults = Object.create( _relative.defaults );
relativeUndoted.defaults.dotted = 0;

//

function relativeCommon()
{
  let commonPath = this.common( filePath );
  let relativePath = [];

  for( let i = 0 ; i < filePath.length ; i++ )
  relativePath[ i ] = this.relative( commonPath, filePath[ i ] );

  return relativePath;
}

//

function _commonSingle( src1, src2 )
{
  let self = this;

  _.assert( arguments.length === 2, 'Expects exactly two arguments' );
  _.assert( _.strIs( src1 ) && _.strIs( src2 ) );

  let split = function( src )
  {
    // debugger;
    return _.strSplitFast( { src : src, delimeter : [ '/' ], preservingDelimeters : 1, preservingEmpty : 1 } );
  }

  let result = [];
  let first = parsePath( src1 );
  let second = parsePath( src2 );

  let needToSwap = first.isRelative && second.isAbsolute;

  if( needToSwap )
  {
    let tmp = second;
    second = first;
    first = tmp;
  }

  let bothAbsolute = first.isAbsolute && second.isAbsolute;
  let bothRelative = first.isRelative && second.isRelative;
  let absoluteAndRelative = first.isAbsolute && second.isRelative;

  if( absoluteAndRelative )
  {
    if( first.splitted.length > 3 || first.splitted[ 0 ] !== '' || first.splitted[ 2 ] !== '' || first.splitted[ 1 ] !== '/' )
    {
      debugger;
      throw _.err( 'Incompatible paths.' );
    }
    else
    return '/';
  }

  if( bothAbsolute )
  {
    getCommon();

    result = result.join('');

    if( !result.length )
    result = '/';
  }

  if( bothRelative )
  {
    // console.log(  first.splitted, second.splitted );

    if( first.levelsDown === second.levelsDown )
    getCommon();

    result = result.join('');

    let levelsDown = Math.max( first.levelsDown, second.levelsDown );

    if( levelsDown > 0 )
    {
      let prefix = _.arrayFillTimes( [], levelsDown, self._downStr );
      prefix = prefix.join( '/' );
      result = prefix + result;
    }

    if( !result.length )
    {
      if( first.isRelativeHereThen && second.isRelativeHereThen )
      result = self._hereStr;
      else
      result = '.';
    }
  }

  // if( result.length > 1 )
  // if( _.strEnds( result, '/' ) )
  // result = result.slice( 0, -1 );

  return result;

  /* - */

  function getCommon()
  {
    let length = Math.min( first.splitted.length, second.splitted.length );
    for( let i = 0; i < length; i++ )
    {
      if( first.splitted[ i ] === second.splitted[ i ] )
      {
        if( first.splitted[ i ] === self._upStr && first.splitted[ i + 1 ] === self._upStr )
        break;
        else
        result.push( first.splitted[ i ] );
      }
      else
      break;
    }
  }

  function parsePath( path )
  {
    let result =
    {
      isRelativeDown : false,
      isRelativeHereThen : false,
      isRelativeHere : false,
      levelsDown : 0
    };

    result.normalized = self.normalize( path );
    result.splitted = split( result.normalized );
    result.isAbsolute = self.isAbsolute( result.normalized );
    result.isRelative = !result.isAbsolute;

    if( result.isRelative )
    if( result.splitted[ 0 ] === self._downStr )
    {
      result.levelsDown = _.arrayCount( result.splitted, self._downStr );
      let substr = _.arrayFillTimes( [], result.levelsDown, self._downStr ).join( '/' );
      let withoutLevels = _.strRemoveBegin( result.normalized, substr );
      result.splitted = split( withoutLevels );
      result.isRelativeDown = true;
    }
    else if( result.splitted[ 0 ] === '.' )
    {
      result.splitted = result.splitted.splice( 2 );
      result.isRelativeHereThen = true;
    }
    else
    result.isRelativeHere = true;

    return result;
  }

}

//

function common()
{

  _.assert( _.strsAre( arguments ) );

  let paths = _.longSlice( arguments );

  paths.sort( function( a, b )
  {
    return b.length - a.length;
  });

  let result = paths.pop();

  for( let i = 0, len = paths.length; i < len; i++ )
  result = this._commonSingle( paths[ i ], result );

  return result;
}

//

function commonReport( filePath )
{
  _.assert( _.strIs( filePath ) || _.arrayIs( filePath ) );
  _.assert( arguments.length === 1 );

  if( _.strIs( filePath ) )
  return filePath;

  let commonPath = this.common.apply( this, filePath );
  let relativePath = [];
  for( let i = 0 ; i < filePath.length ; i++ )
  relativePath[ i ] = this.relative( commonPath, filePath[ i ] );

  return commonPath + ' + ' + '( ' + relativePath.join( ' , ' ) + ' )';
}

//

function moveReport( dst, src )
{
  let result = '';

  let c = ( _.uri && _.uri.isGlobal( src ) ) ? '' : this.common( dst, src );
  if( c.length > 1 )
  result = c + ' : ' + this.relative( c,dst ) + ' <- ' + this.relative( c,src );
  else
  result = dst + ' <- ' + src;

  return result;
}

//

function rebase( filePath, oldPath, newPath )
{

  _.assert( arguments.length === 3, 'Expects exactly three argument' );

  filePath = this.normalize( filePath );
  if( oldPath )
  oldPath = this.normalize( oldPath );
  newPath = this.normalize( newPath );

  if( oldPath )
  {
    let commonPath = this.common( filePath,oldPath );
    filePath = _.strRemoveBegin( filePath,commonPath );
  }

  filePath = this.reroot( newPath,filePath )

  return filePath;
}

//

function _onErrorNotSafe( prefix, filePath, level, err )
{
  debugger;
  _.assert( arguments.length === 4 );
  _.assert( _.strIs( prefix ) );
  _.assert( _.strIs( filePath ) );
  _.assert( _.numberIs( level ) );
  _.assert( _.errIs( err ) );
  let args = [ prefix + ( prefix ? '. ' : '' ) + 'Not safe to use file ' + _.strQuote( filePath ) + '. Please decrease {- safe -} if you are know what you do, current {- safe = ' + level + ' -}' ];
  return _.err.apply( _, arguments );
}

let ErrorNotSafe = _.error_functor( 'ErrorNotSafe', _onErrorNotSafe );

// --
// fields
// --

let Parameters =
{

  _rootStr : '/',
  _upStr : '/',
  _hereStr : '.',
  _downStr : '..',
  _hereUpStr : null,
  _downUpStr : null,

  _upEscapedStr : null,
  _butDownUpEscapedStr : null,
  _delDownEscapedStr : null,
  _delDownEscaped2Str : null,
  _delUpRegexp : null,
  _delHereRegexp : null,
  _delDownRegexp : null,
  _delDownFirstRegexp : null,
  _delUpDupRegexp : null,

}

let Fields =
{

  Parameters : Parameters,

  fileProvider : null,
  path : Self,
  single : Self,
  s : null,

}

// --
// routines
// --

let Routines =
{

  // internal

  Init : Init,
  CloneExtending : CloneExtending,

  _pathMultiplicator_functor : _pathMultiplicator_functor,
  _filterNoInnerArray : _filterNoInnerArray,
  _filterOnlyPath : _filterOnlyPath,

  // path tester

  is : is,
  are : are,
  like : like,
  isSafe : isSafe,
  isNormalized : isNormalized,
  isRefined : isRefined,
  isAbsolute : isAbsolute,
  isRelative : isRelative,
  isGlobal : isGlobal,
  isRoot : isRoot,
  isDotted : isDotted,
  isTrailed : isTrailed,

  begins : begins,
  ends : ends,

  // normalizer

  refine : refine,

  _pathNormalize : _pathNormalize,
  normalize : normalize,

  normalizeTolerant : normalizeTolerant,

  _pathNativizeWindows : _pathNativizeWindows,
  _pathNativizeUnix : _pathNativizeUnix,
  nativize : nativize,

  dot : dot,
  undot : undot,
  trail : trail,
  detrail : detrail,

  // path join

  _pathJoinAct : _pathJoinAct,
  // _pathsJoin_body : _pathsJoin_body,

  join : join,

  joinIfDefined : joinIfDefined,
  crossJoin : crossJoin,

  reroot : reroot,

  resolve : resolve,

  split : split,
  _split : _split,

  dir : dir,

  prefixGet : prefixGet,

  name : name,
  fullName : fullName,
  nameJoin : nameJoin, /* qqq : cover */

  withoutExt : withoutExt,

  changeExt : changeExt,

  ext : ext,

  exts : exts,

  current : current,
  from : from,

  _relative : _relative,
  relative : relative,
  relativeUndoted : relativeUndoted,
  relativeCommon : relativeCommon,

  _commonSingle : _commonSingle,
  common : common,
  commonReport : commonReport,

  moveReport : moveReport,

  rebase : rebase,

  ErrorNotSafe : ErrorNotSafe,

}

_.mapSupplement( Self, Parameters );
_.mapSupplement( Self, Fields );
_.mapSupplement( Self, Routines );

Self.Init();

// --
// export
// --

// if( typeof module !== 'undefined' )
// if( _global_.WTOOLS_PRIVATE )
// { /* delete require.cache[ module.id ]; */ }

if( typeof module !== 'undefined' && module !== null )
module[ 'exports' ] = Self;

if( typeof module !== 'undefined' )
{
  require( '../l4/Paths.s' );
  require( '../l7/Glob.s' );
}

/*

qqq : extend it to supoort

_.path.nameJoin( 'a.b', 'x.y' ) -> 'ax.by'
_.path.nameJoin( '.', 'a.b', 'x.y' ) -> 'ax.by'

_.path.nameJoin( '/pre.x', 'a.y/b/c.name', 'post.z' ) -> '/pre.x/a.y/b/cpost.namez'
_.path.nameJoin( './pre.x', 'a.y/b/c.name', 'post.z' ) -> 'a.y/b/precpost.xnamez'

_.path.nameJoin( 'pre.x', 'a.y/b/c.name', 'post.z' ) -> 'a.y/b/precpost.xnamez'
_.path.nameJoin( 'pre.x', 'a.y/b/c.name', './post.z' ) -> 'a.y/b/precpost.xnamez'
_.path.nameJoin( 'pre.x', 'a.y/./b/./c.name', './post.z' ) -> 'a.y/b/precpost.xnamez'
_.path.nameJoin( '././pre.x', 'a.y/b/c.name/./.', 'post.z' ) -> 'a.y/b/precpost.xnamez'

_.path.nameJoin( 'pre.x', 'a.y/b/c.name', 'd/post.z' ) -> 'a.y/bd/precpost.xnamez'
_.path.nameJoin( 'pre1.x1/pre.x', 'a.y/b/c.name', 'd/post.z' ) -> 'a.y/pre1bd.x1/precpost.xnamez'
_.path.nameJoin( '/pre1.x1/pre.x', 'a.y/b/c.name', 'd/post.z' ) -> '/pre1.x1/pre.x/a.y/bd/cpost.namex'

*/

})();
